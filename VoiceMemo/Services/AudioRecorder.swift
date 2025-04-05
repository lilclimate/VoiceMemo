//
//  AudioRecorder.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import Foundation
import AVFoundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordedFileURL: URL? = nil
    @Published var recordingTime: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    override init() {
        super.init()
        setupRecordingSession()
    }
    
    deinit {
        stopRecording()
    }
    
    private func setupRecordingSession() {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            session.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    if !allowed {
                        print("麦克风权限被拒绝")
                    }
                }
            }
        } catch {
            print("设置录音会话失败: \(error.localizedDescription)")
        }
    }
    
    func startRecording() {
        // 使用wav格式，这是API支持的格式之一
        let audioFilename = getDocumentsDirectory().appendingPathComponent("\(Date().timeIntervalSince1970).wav")
        
        // 使用线性PCM格式，这是最常见的WAV存储格式
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1, // 单声道可能更合适处理语音
            AVLinearPCMBitDepthKey: 16, // 16位深度
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            self.isRecording = true
            self.recordingTime = 0
            self.recordedFileURL = audioFilename
            
            // 启动计时器
            self.timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingTime += 0.1
            }
        } catch {
            print("录音失败: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        
        timer?.invalidate()
        timer = nil
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    // 录音时长格式化
    func formattedRecordingTime() -> String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        let tenths = Int((recordingTime * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%01d", minutes, seconds, tenths)
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordedFileURL = nil
        }
        
        isRecording = false
    }
}
