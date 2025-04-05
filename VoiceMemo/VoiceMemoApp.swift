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
    // 引用CoreDataManager确保它在App启动时初始化
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    // 初始化时设置音频会话
    init() {
        // 在初始化时打印信息方便调试
        print("VoiceMemoApp 初始化")
        
        // 初始化数据管理器
        let _ = CoreDataManager.shared
        setupAudioSession()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, CoreDataManager.shared.persistentContainer.viewContext)
                .onAppear {
                    print("ContentView 显示")
                }
        }
    }
    
    // 设置音频会话
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            print("音频会话设置成功")
        } catch {
            print("设置音频会话失败: \(error.localizedDescription)")
        }
    }
}

// App代理，用于处理应用生命周期事件
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        print("App启动完成")
        return true
    }
}
