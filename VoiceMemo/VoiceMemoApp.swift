//
//  VoiceMemoApp.swift
//  VoiceMemo
//
//  Created by 张元熙 on 2025/4/5.
//

import SwiftUI
import CoreData
import AVFoundation

@main
struct VoiceMemoApp: App {
    // 确保Core Data模型已正确加载
    init() {
        setupAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    // 设置音频会话
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
        }
    }
}
