import SwiftUI

/// 乐谱库列表页
struct LibraryPage: View {
    @StateObject private var viewModel = LibraryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else if viewModel.scores.isEmpty {
                    emptyView
                } else {
                    listView
                }
            }
            .navigationTitle("我的乐谱")
            .onAppear { viewModel.loadScores() }
        }
    }

    // MARK: - Empty State

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("还没有乐谱")
                .font(.title2)
                .foregroundColor(.secondary)
            Text("切换到「拍照识别」标签页\n拍摄你的第一份乐谱")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - List

    private var listView: some View {
        List {
            ForEach(viewModel.scores) { score in
                NavigationLink(destination: ScoreDetailPage(score: score)) {
                    ScoreRow(score: score)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        viewModel.deleteScore(score)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Row

private struct ScoreRow: View {
    let score: ScoreItem

    var body: some View {
        HStack(spacing: 12) {
            // 缩略图占位
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "music.note")
                        .foregroundColor(.accentColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(score.title)
                    .font(.headline)
                    .lineLimit(1)
                if !score.artist.isEmpty {
                    Text(score.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if !score.isCached {
                Image(systemName: "icloud.and.arrow.down")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
