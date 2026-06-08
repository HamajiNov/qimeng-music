//
//  QXProfilePage.swift
//  QXMusicApp
//

import SwiftUI
import LXAnnotation
import QXMusicInterface

struct QXProfilePage: View {
    @State private var cacheSize = ""
    @State private var scores: [QXScoreItem] = []
    @State private var showClear = false

    var body: some View {
        NavigationStack {
            List {
                Section("存储") {
                    HStack { Text("缓存大小"); Spacer(); Text(cacheSize).foregroundColor(.secondary) }
                    Button("清除所有缓存", role: .destructive) { showClear = true }
                }
                Section("关于") {
                    HStack { Text("版本"); Spacer(); Text("1.0.0").foregroundColor(.secondary) }
                    HStack { Text("应用"); Spacer(); Text("启蒙乐谱").foregroundColor(.secondary) }
                }
            }
            .navigationTitle("我的")
        }
        .onAppear { load() }
        .alert("确认清除", isPresented: $showClear) {
            Button("取消", role: .cancel) {}
            Button("确认清除", role: .destructive) { clearAll() }
        } message: { Text("将删除所有已下载的乐谱和音频文件，不可撤销。") }
    }

    private func load() {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        cacheSize = storage.cacheSizeFormatted
        scores = storage.loadScores()
    }

    private func clearAll() {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        for s in scores { try? storage.removeScore(s) }
        cacheSize = storage.cacheSizeFormatted
        scores = []
    }
}
