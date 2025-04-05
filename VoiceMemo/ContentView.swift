//
//  ContentView.swift
//  VoiceMemo
//
//  Created by 张元熙 on 2025/4/5.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = MemoViewModel()
    
    var body: some View {
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
            
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .accentColor(.blue)
    }
}

#Preview {
    ContentView()
}
