import SwiftUI

/// 乐谱详情页：乐谱展示 + 播放控制 + KTV 歌词
struct ScoreDetailPage: View {
    let score: ScoreItem
    @StateObject private var player = PlayerViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            if player.isLoading {
                Spacer()
                ProgressView("加载乐谱...")
                Spacer()
            } else {
                // 乐谱展示区
                SheetMusicWebView(musicxmlURL: score.musicxmlURL)
                    .frame(maxHeight: .infinity)

                Divider()

                // KTV 歌词区
                KTVLyricsView(
                    lyrics: player.lyrics,
                    currentIndex: player.currentLyricIndex
                )
                .frame(height: 180)

                Divider()

                // 播放控制栏
                PlaybackControlBar(player: player)
            }
        }
        .navigationTitle(score.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await player.load(score: score) }
        }
        .onDisappear {
            player.stop()
        }
    }
}

// MARK: - Playback Control Bar

private struct PlaybackControlBar: View {
    @ObservedObject var player: PlayerViewModel

    var body: some View {
        VStack(spacing: 8) {
            // 进度条
            HStack {
                Text(player.formattedCurrentTime)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)

                Slider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    in: 0...max(player.duration, 0.1)
                )

                Text(player.formattedDuration)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // 控制按钮
            HStack(spacing: 40) {
                Button { player.skipBackward() } label: {
                    Image(systemName: "gobackward.10")
                        .font(.title2)
                }
                .buttonStyle(.plain)

                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48))
                }
                .buttonStyle(.plain)

                Button { player.skipForward() } label: {
                    Image(systemName: "goforward.10")
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}
