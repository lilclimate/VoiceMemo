//
//  HomeView.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: MemoViewModel
    @State private var showingRecordingControls = false
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    // 如果有当前备忘录，则显示其内容
                    if !viewModel.currentMemo.originalTranscription.isEmpty {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                // 原始转录文本
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("原始转录")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    
                                    Text(viewModel.currentMemo.originalTranscription)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                                
                                // 润色后文本
                                if !viewModel.currentMemo.enhancedTranscription.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("润色后内容")
                                            .font(.headline)
                                            .foregroundColor(.gray)
                                        
                                        Text(viewModel.currentMemo.enhancedTranscription)
                                            .padding()
                                            .background(Color(.systemGray6))
                                            .cornerRadius(8)
                                    }
                                    
                                    // 标签
                                    if !viewModel.currentMemo.tags.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("相关标签")
                                                .font(.headline)
                                                .foregroundColor(.gray)
                                            
                                            HStack {
                                                ForEach(viewModel.currentMemo.tags, id: \.self) { tag in
                                                    Text(tag)
                                                        .padding(.horizontal, 12)
                                                        .padding(.vertical, 5)
                                                        .background(Color.blue.opacity(0.1))
                                                        .foregroundColor(.blue)
                                                        .cornerRadius(15)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding()
                        }
                    } else {
                        // 空状态
                        VStack(spacing: 20) {
                            Image(systemName: "mic.circle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.blue)
                            
                            Text("点击下方按钮开始录音")
                                .font(.headline)
                                .foregroundColor(.gray)
                        }
                        .frame(maxHeight: .infinity)
                    }
                    
                    Spacer()
                    
                    // 录音按钮
                    RecordButton(isRecording: $showingRecordingControls)
                        .padding(.bottom, 30)
                        .onTapGesture {
                            if viewModel.getAudioRecorder().isRecording {
                                viewModel.stopRecordingAndProcess()
                            } else {
                                viewModel.startRecording()
                            }
                            showingRecordingControls.toggle()
                        }
                }
                
                // 加载提示
                if viewModel.isProcessing {
                    Color.black.opacity(0.3)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("正在处理你的录音...")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                    .frame(width: 200, height: 120)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            .navigationTitle("语音备忘录")
        }
        .alert(item: Binding(
            get: { viewModel.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { _ in viewModel.errorMessage = nil }
        )) { errorWrapper in
            Alert(
                title: Text("错误"),
                message: Text(errorWrapper.error),
                dismissButton: .default(Text("确定"))
            )
        }
    }
}

struct RecordButton: View {
    @Binding var isRecording: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isRecording ? Color.red : Color.blue)
                .frame(width: 70, height: 70)
            
            if isRecording {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
            } else {
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .padding(10)
            }
        }
    }
}

struct ErrorWrapper: Identifiable {
    let id = UUID()
    let error: String
}

#Preview {
    HomeView()
        .environmentObject(MemoViewModel())
}
