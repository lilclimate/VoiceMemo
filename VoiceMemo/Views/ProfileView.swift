//
//  ProfileView.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import SwiftUI

struct ProfileView: View {
    @State private var showingAbout = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("个人信息")) {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("用户")
                                .font(.headline)
                            Text("VoiceMemo用户")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.leading, 8)
                    }
                }
                
                Section(header: Text("设置")) {
                    NavigationLink(destination: SettingsView()) {
                        HStack {
                            Image(systemName: "gear")
                                .frame(width: 25, height: 25)
                                .foregroundColor(.gray)
                            Text("通用设置")
                        }
                    }
                    
                    Button(action: {
                        showingAbout = true
                    }) {
                        HStack {
                            Image(systemName: "info.circle")
                                .frame(width: 25, height: 25)
                                .foregroundColor(.gray)
                            Text("关于应用")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                                .font(.caption)
                        }
                    }
                }
                
                Section(header: Text("反馈")) {
                    HStack {
                        Image(systemName: "envelope")
                            .frame(width: 25, height: 25)
                            .foregroundColor(.gray)
                        Text("发送反馈")
                    }
                }
                
                Section(footer: Text("VoiceMemo版本 1.0.0")) {
                    EmptyView()
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("我的")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct SettingsView: View {
    @State private var enableDarkMode = false
    @State private var enableICloudSync = false
    @State private var saveHighQualityAudio = true
    @State private var languageSelection = 0
    
    let languages = ["简体中文", "English", "日本語"]
    
    var body: some View {
        Form {
            Section(header: Text("界面设置")) {
                Toggle("深色模式", isOn: $enableDarkMode)
                
                Picker("语言", selection: $languageSelection) {
                    ForEach(0..<languages.count, id: \.self) { index in
                        Text(languages[index])
                    }
                }
            }
            
            Section(header: Text("数据设置")) {
                Toggle("启用iCloud同步", isOn: $enableICloudSync)
                Toggle("保存高质量音频", isOn: $saveHighQualityAudio)
            }
        }
        .navigationTitle("设置")
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text("VoiceMemo")
                .font(.largeTitle)
                .bold()
            
            Text("版本 1.0.0")
                .foregroundColor(.gray)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("VoiceMemo是一款语音备忘录应用，它使用先进的AI技术将您的语音转换为文字，并提供智能润色和主题标签提取功能。")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("© 2025 VoiceMemo 团队")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
            }
            
            Spacer()
            
            Button("关闭") {
                // 关闭视图
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    ProfileView()
}
