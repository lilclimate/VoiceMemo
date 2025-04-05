//
//  TestView.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import SwiftUI

struct TestView: View {
    @State private var testMessage = "测试视图已加载"
    
    var body: some View {
        VStack(spacing: 20) {
            Text("语音备忘录")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text(testMessage)
                .font(.headline)
                .foregroundColor(.green)
            
            Button(action: {
                testMessage = "按钮点击成功！\n当前时间: \(Date().formatted())"
            }) {
                Text("点击测试按钮")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
            
            Text("此视图用于测试应用基本功能")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .onAppear {
            print("TestView出现，应用正在运行")
        }
    }
}

#Preview {
    TestView()
}
