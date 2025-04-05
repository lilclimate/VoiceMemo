//
//  APITestView.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import SwiftUI
import AVFoundation

struct APITestView: View {
    @State private var testMessage = "API测试视图"
    @State private var isRecording = false
    @State private var isProcessing = false
    @State private var errorMessage: String? = nil
    @State private var testResults: String = ""
    
    // 创建一个测试用的AudioRecorder实例
    private let audioRecorder = AudioRecorder()
    private let apiService = APIService()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("API测试工具")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                // 录音按钮
                Button(action: {
                    if isRecording {
                        stopRecordingAndTest()
                    } else {
                        startRecording()
                    }
                }) {
                    Text(isRecording ? "停止录音并测试API" : "开始录音")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(isRecording ? Color.red : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(isProcessing)
                
                if isProcessing {
                    ProgressView("正在处理...")
                }
                
                if let error = errorMessage {
                    Text("错误: \(error)")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(10)
                }
                
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("测试结果:")
                            .font(.headline)
                        
                        Text(testResults)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
                
                Text("此视图用于测试API连接")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .onAppear {
                // 设置音频会话
                setupAudioSession()
            }
        }
    }
    
    // 开始录音
    private func startRecording() {
        self.errorMessage = nil
        self.testResults = ""
        audioRecorder.startRecording()
        isRecording = true
    }
    
    // 停止录音并测试API
    private func stopRecordingAndTest() {
        audioRecorder.stopRecording()
        isRecording = false
        
        guard let audioURL = audioRecorder.recordedFileURL else {
            self.errorMessage = "没有找到录音文件"
            return
        }
        
        self.isProcessing = true
        self.testResults = "正在测试API...\n"
        
        // 第一步：测试音频转文字API
        apiService.transcribeAudio(audioURL: audioURL)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        self.testResults += "✅ 音频转文字API测试成功\n"
                    case .failure(let error):
                        self.errorMessage = "音频转文字API失败: \(error.localizedDescription)"
                        self.testResults += "❌ 音频转文字API测试失败: \(error.localizedDescription)\n"
                        self.isProcessing = false
                    }
                },
                receiveValue: { transcription in
                    // 第二步：测试文字润色API
                    self.testResults += "🎉 收到转录文本: \(transcription)\n"
                    
                    // 如果文本为空，使用一个测试文本
                    let textToEnhance = transcription.isEmpty ? "这是一个测试文本，用于测试文字润色API功能。" : transcription
                    
                    apiService.enhanceText(text: textToEnhance)
                        .receive(on: DispatchQueue.main)
                        .sink(
                            receiveCompletion: { completion in
                                self.isProcessing = false
                                switch completion {
                                case .finished:
                                    self.testResults += "✅ 文字润色API测试成功\n"
                                case .failure(let error):
                                    self.errorMessage = "文字润色API失败: \(error.localizedDescription)"
                                    self.testResults += "❌ 文字润色API测试失败: \(error.localizedDescription)\n"
                                }
                            },
                            receiveValue: { (enhancedText, tags) in
                                self.testResults += "🎉 润色后文本: \(enhancedText)\n"
                                self.testResults += "🏷️ 提取的标签: \(tags.joined(separator: ", "))\n"
                            }
                        )
                }
            )
    }
    
    // 设置音频会话
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            self.testResults += "音频会话设置成功\n"
        } catch {
            self.errorMessage = "设置音频会话失败: \(error.localizedDescription)"
        }
    }
}

#Preview {
    APITestView()
}
