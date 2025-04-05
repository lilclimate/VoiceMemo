//
//  MemoViewModel.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import Foundation
import Combine
import SwiftUI

class MemoViewModel: ObservableObject {
    // 数据状态
    @Published var memos: [Memo] = []
    @Published var currentMemo: Memo = Memo.empty
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil
    
    // 服务
    private let apiService = APIService()
    private let dataManager = DataManager.shared
    private let audioRecorder = AudioRecorder()
    
    // 取消标记
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 将audioRecorder的状态绑定到ViewModel
        audioRecorder.$isRecording
            .sink { [weak self] isRecording in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        // 加载所有备忘录
        loadMemos()
    }
    
    // 获取audioRecorder
    func getAudioRecorder() -> AudioRecorder {
        return audioRecorder
    }
    
    // 加载所有备忘录
    func loadMemos() {
        dataManager.fetchAllMemos()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "加载备忘录失败: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] memos in
                self?.memos = memos
            })
            .store(in: &cancellables)
    }
    
    // 开始录音
    func startRecording() {
        audioRecorder.startRecording()
    }
    
    // 停止录音并处理
    func stopRecordingAndProcess() {
        audioRecorder.stopRecording()
        
        guard let audioURL = audioRecorder.recordedFileURL else {
            self.errorMessage = "没有找到录音文件"
            return
        }
        
        self.isProcessing = true
        self.errorMessage = nil
        self.currentMemo = Memo(
            date: Date(),
            audioURL: audioURL,
            originalTranscription: "",
            enhancedTranscription: "",
            tags: []
        )
        
        // 语音转文字
        apiService.transcribeAudio(audioURL: audioURL)
            .receive(on: DispatchQueue.main)
            .flatMap { [weak self] transcription -> AnyPublisher<(String, [String]), Error> in
                guard let self = self else {
                    return Fail(error: DataError.managerDeallocated).eraseToAnyPublisher()
                }
                
                self.currentMemo.originalTranscription = transcription
                return self.apiService.enhanceText(text: transcription)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "处理录音失败: \(error.localizedDescription)"
                }
                self?.isProcessing = false
            }, receiveValue: { [weak self] (enhancedText, tags) in
                guard let self = self else { return }
                
                self.currentMemo.enhancedTranscription = enhancedText
                self.currentMemo.tags = tags
                
                // 保存到数据库
                self.saveMemo(self.currentMemo)
            })
            .store(in: &cancellables)
    }
    
    // 保存备忘录
    func saveMemo(_ memo: Memo) {
        dataManager.saveMemo(memo: memo)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "保存备忘录失败: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] _ in
                self?.loadMemos() // 刷新备忘录列表
            })
            .store(in: &cancellables)
    }
    
    // 删除备忘录
    func deleteMemo(at indexSet: IndexSet) {
        for index in indexSet {
            let memo = memos[index]
            dataManager.deleteMemo(id: memo.id)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = "删除备忘录失败: \(error.localizedDescription)"
                    }
                }, receiveValue: { [weak self] _ in
                    self?.loadMemos() // 刷新备忘录列表
                })
                .store(in: &cancellables)
        }
    }
    
    // 格式化日期
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}
