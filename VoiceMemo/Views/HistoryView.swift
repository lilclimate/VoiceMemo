//
//  HistoryView.swift
//  VoiceMemo
//
//  Created for VoiceMemo App.
//

import SwiftUI
import AVFoundation

struct HistoryView: View {
    @EnvironmentObject var viewModel: MemoViewModel
    @State private var selectedMemo: Memo?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.memos.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "clock.arrow.circlepath")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("暂无录音记录")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.memos) { memo in
                            MemoListItem(memo: memo)
                                .onTapGesture {
                                    selectedMemo = memo
                                }
                        }
                        .onDelete(perform: viewModel.deleteMemo)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("历史记录")
            .sheet(item: $selectedMemo) { memo in
                MemoDetailView(memo: memo, audioPlayer: $audioPlayer, isPlaying: $isPlaying)
                    .environmentObject(viewModel)
            }
        }
    }
}

struct MemoListItem: View {
    let memo: Memo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "waveform")
                    .foregroundColor(.blue)
                
                Text(formattedDate(memo.date))
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Spacer()
            }
            
            Text(memo.enhancedTranscription.isEmpty ? memo.originalTranscription : memo.enhancedTranscription)
                .lineLimit(2)
                .font(.body)
            
            if !memo.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(memo.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: date)
    }
}

struct MemoDetailView: View {
    let memo: Memo
    @Binding var audioPlayer: AVAudioPlayer?
    @Binding var isPlaying: Bool
    @EnvironmentObject var viewModel: MemoViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 播放控制
                    if let _ = memo.audioURL {
                        HStack {
                            Button(action: {
                                togglePlay()
                            }) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: 44, height: 44)
                                    .foregroundColor(.blue)
                            }
                            
                            Text(isPlaying ? "正在播放..." : "播放录音")
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    
                    // 原始转录
                    VStack(alignment: .leading, spacing: 8) {
                        Text("原始转录")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(memo.originalTranscription)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    
                    // 润色后内容
                    if !memo.enhancedTranscription.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("润色后内容")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Text(memo.enhancedTranscription)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                    
                    // 标签
                    if !memo.tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("相关标签")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                ForEach(memo.tags, id: \.self) { tag in
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
                    
                    // 录音日期
                    VStack(alignment: .leading, spacing: 8) {
                        Text("录音时间")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(viewModel.formatDate(memo.date))
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("备忘详情")
            .navigationBarItems(trailing: Button("关闭") {
                presentationMode.wrappedValue.dismiss()
            })
            .onDisappear {
                stopPlaying()
            }
        }
    }
    
    func togglePlay() {
        // 如果已经在播放，则停止
        if isPlaying {
            stopPlaying()
            return
        }
        
        // 否则开始播放
        guard let audioURL = memo.audioURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.delegate = AVPlayerObserver(isPlaying: $isPlaying)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("播放音频失败: \(error.localizedDescription)")
        }
    }
    
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }
}

// 音频播放器观察者
class AVPlayerObserver: NSObject, AVAudioPlayerDelegate {
    @Binding var isPlaying: Bool
    
    init(isPlaying: Binding<Bool>) {
        self._isPlaying = isPlaying
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
        }
    }
}

#Preview {
    HistoryView()
        .environmentObject(MemoViewModel())
}
