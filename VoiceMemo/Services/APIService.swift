//
//  APIService.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import Foundation
import Combine

class APIService {
    private let apiKey = "sk-nrmdoujdbmbqorvlcwdwoaontubfxniptxmvjubzhgqpiroe"
    private let transcriptionURL = "https://api.siliconflow.cn/v1/audio/transcriptions"
    private let completionsURL = "https://api.siliconflow.cn/v1/chat/completions"
    
    // 语音转文字
    func transcribeAudio(audioURL: URL) -> AnyPublisher<String, Error> {
        let fileName = audioURL.lastPathComponent
        
        var request = URLRequest(url: URL(string: transcriptionURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        
        // 添加模型参数
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        data.append("FunAudioLLM/SenseVoiceSmall\r\n".data(using: .utf8)!)
        
        // 添加音频文件
        do {
            let audioData = try Data(contentsOf: audioURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: audio/mpeg\r\n\r\n".data(using: .utf8)!)
            data.append(audioData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        
        // 添加语言参数
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
        data.append("zh\r\n".data(using: .utf8)!)
        
        // 结束边界
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = data
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError("无法获取HTTP响应")
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    // 尝试解析错误响应
                    let errorString = String(data: data, encoding: .utf8) ?? "未知服务器错误"
                    print("API请求失败: \(httpResponse.statusCode), 错误信息: \(errorString)")
                    throw APIError.serverError(errorString)
                }
                
                return data
            }
            .decode(type: TranscriptionResponse.self, decoder: JSONDecoder())
            .map { $0.text }
            .eraseToAnyPublisher()
    }
    
    // 文字润色和提取标签
    func enhanceText(text: String) -> AnyPublisher<(String, [String]), Error> {
        var request = URLRequest(url: URL(string: completionsURL)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = """
        请帮我润色以下文本，使其更流畅、更连贯，同时修正可能存在的错别字。此外，请提供与文本内容相关的3个主题标签，以"#标签"的格式呈现。最后，提出关于这个话题的下一步思考方向。请按以下格式返回：

        润色后的文本：[润色后的内容]

        下一步思考方向：[思考方向]

        标签：#标签1 #标签2 #标签3

        原文：\(text)
        """
        
        let body: [String: Any] = [
            "model": "Pro/THUDM/glm-4-9b-chat", // 使用SiliconFlow支持的模型
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 2000,
            "temperature": 0.7 // 添加温度参数以控制创造性
        ]
        
        let jsonData = try? JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonData
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.networkError("无法获取HTTP响应")
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    // 尝试解析错误响应
                    let errorString = String(data: data, encoding: .utf8) ?? "未知服务器错误"
                    print("API请求失败: \(httpResponse.statusCode), 错误信息: \(errorString)")
                    throw APIError.serverError(errorString)
                }
                
                return data
            }
            .decode(type: CompletionResponse.self, decoder: JSONDecoder())
            .map { response in
                guard let content = response.choices.first?.message.content else {
                    return ("", [])
                }
                
                // 解析内容
                var enhancedText = ""
                var tags: [String] = []
                
                if let enhancedRange = content.range(of: "润色后的文本：", options: .literal)?.upperBound,
                   let nextSection = content.range(of: "\n\n下一步思考方向：", options: .literal)?.lowerBound {
                    enhancedText = String(content[enhancedRange..<nextSection])
                }
                
                // 提取标签
                if let tagsRange = content.range(of: "标签：", options: .literal)?.upperBound {
                    let tagsText = String(content[tagsRange...])
                    tags = tagsText.components(separatedBy: " ")
                        .filter { $0.hasPrefix("#") }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                }
                
                return (enhancedText.trimmingCharacters(in: .whitespacesAndNewlines), tags)
            }
            .eraseToAnyPublisher()
    }
}

// 响应模型
struct TranscriptionResponse: Decodable {
    let text: String
}

struct CompletionResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}

enum APIError: Error {
    case serverError(String)
    case networkError(String)
    case decodingError(String)
    
    var localizedDescription: String {
        switch self {
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .networkError(let message):
            return "网络连接错误: \(message)"
        case .decodingError(let message):
            return "数据解析错误: \(message)"
        }
    }
}
