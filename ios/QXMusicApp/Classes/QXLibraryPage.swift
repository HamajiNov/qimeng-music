//
//  QXLibraryPage.swift
//  QXMusicApp
//

import SwiftUI
import LXAnnotation
import QXMusicInterface

struct QXLibraryPage: View {
    @State private var scores: [QXScoreItem] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading { ProgressView("加载中...") }
                else if scores.isEmpty { emptyView }
                else { listView }
            }
            .navigationTitle("我的乐谱")
        }
        .onAppear { load() }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list").font(.system(size: 60)).foregroundColor(.secondary)
            Text("还没有乐谱").font(.title2).foregroundColor(.secondary)
            Text("切换到「拍照识别」标签页\n拍摄你的第一份乐谱")
                .foregroundColor(.secondary).multilineTextAlignment(.center)
        }
    }

    private var listView: some View {
        List {
            ForEach(scores, id: \.id) { score in
                NavigationLink(destination: QXScoreDetailPage(score: score)) {
                    QXScoreRow(score: score)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        removeScore(score)
                    } label: { Label("删除", systemImage: "trash") }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func load() {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        scores = storage.loadScores()
        isLoading = false
    }

    private func removeScore(_ score: QXScoreItem) {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self) as? QXStorageProtocol else { return }
        try? storage.removeScore(score)
        scores.removeAll { $0.id == score.id }
    }
}

private struct QXScoreRow: View {
    let score: QXScoreItem
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: "music.note").foregroundColor(.accentColor))
            VStack(alignment: .leading, spacing: 4) {
                Text(score.title).font(.headline).lineLimit(1)
                if !score.artist.isEmpty {
                    Text(score.artist).font(.subheadline).foregroundColor(.secondary)
                }
            }
            Spacer()
        }.padding(.vertical, 4)
    }
}
