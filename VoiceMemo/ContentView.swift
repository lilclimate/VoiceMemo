//
//  ContentView.swift
//  VoiceMemo
//
//  Created by 张元熙 on 2025/4/5.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MemoViewModel()
    @State private var isLoading = true
    @State private var showingAPITest = false
    
    var body: some View {
        ZStack {
            if isLoading {
                // 加载中的视图
                VStack {
                    TestView()
                    
                    Button("API测试工具") {
                        showingAPITest = true
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .sheet(isPresented: $showingAPITest) {
                        APITestView()
                    }
                }
                .onAppear {
                    // 延迟2秒后结束加载状态，给系统足够时间初始化
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isLoading = false
                    }
                }
            } else {
                // 主界面
                TabView {
                    HomeView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("首页", systemImage: "mic")
                        }
                    
                    HistoryView()
                        .environmentObject(viewModel)
                        .tabItem {
                            Label("历史", systemImage: "clock")
                        }
                    
                    VStack {
                        ProfileView()
                        
                        Button("API测试工具") {
                            showingAPITest = true
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .tabItem {
                        Label("我的", systemImage: "person")
                    }
                }
                .accentColor(.blue)
                .sheet(isPresented: $showingAPITest) {
                    APITestView()
                }
            }
        }
        .onAppear {
            print("ContentView已加载")
            // 初始化viewModel
            viewModel.loadMemos()
        }
    }
}

#Preview {
    ContentView()
}
