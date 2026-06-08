//
//  QXScoreDetailPage.swift
//  QXMusicApp
//

import SwiftUI
import LXAnnotation
import QXMusicInterface
import QXScoreKit
import QXPlayerKit

struct QXScoreDetailPage: View {
    let score: QXScoreItem
    @Environment(\.dismiss) private var dismiss
    @State private var player: QXPlayerProtocol?
    @State private var renderer: QXSheetMusicRenderer?
    @State private var refreshToggle = false

    var body: some View {
        VStack(spacing: 0) {
            if let p = player, let r = renderer {
                if p.isLoading {
                    Spacer()
                    ProgressView("加载乐谱...")
                    Spacer()
                } else {
                    // 乐谱展示
                    QXSheetMusicView(renderer: r).frame(maxHeight: .infinity)
                    Divider()
                    // KTV 歌词
                    QXKTVLyricsView(lyrics: p.lyrics, currentIndex: p.currentLyricIndex)
                        .frame(height: 180)
                    Divider()
                    // 播放控制
                    QXPlaybackBar(player: p)
                }
            } else {
                Spacer()
                ProgressView("正在初始化...")
                Spacer()
            }
        }
        .navigationTitle(score.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { setup() }
        .onDisappear { player?.stop() }
        .id(refreshToggle)
    }

    private func setup() {
        let p = (LXAnnotation.getInstance(
            forProtocolType: QXPlayerProtocol.self) as? QXPlayerProtocol)!
        let r = (LXAnnotation.getInstance(
            forProtocolType: QXScoreProtocol.self) as? QXSheetMusicRenderer)!

        p.onStateChanged = { refreshToggle.toggle() }
        self.player = p
        self.renderer = r

        Task {
            // 加载乐谱渲染
            let musicxmlURL = QXScoreLibraryManager.shared.scoresDirectory
                .appendingPathComponent(score.id).appendingPathComponent("score.musicxml")
            r.loadMusicXML(url: musicxmlURL)
            // 加载播放器
            await p.load(score: score)
        }
    }
}

// MARK: - KTV Lyrics

struct QXKTVLyricsView: View {
    let lyrics: [QXLRCLine]
    let currentIndex: Int

    var body: some View {
        if lyrics.isEmpty {
            VStack { Image(systemName: "text.alignleft").foregroundColor(.secondary); Text("无歌词").font(.caption).foregroundColor(.secondary) }
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        Color.clear.frame(height: 60)
                        ForEach(Array(lyrics.enumerated()), id: \.offset) { i, line in
                            Text(line.text)
                                .font(i == currentIndex ? .title3.weight(.bold) : .body)
                                .foregroundColor(i == currentIndex ? .primary : .secondary.opacity(0.5))
                                .scaleEffect(i == currentIndex ? 1.1 : 0.95)
                                .animation(.easeInOut(duration: 0.3), value: currentIndex)
                                .id(i)
                        }
                        Color.clear.frame(height: 100)
                    }.padding(.horizontal, 32)
                }
                .onChange(of: currentIndex) { _, new in
                    withAnimation(.easeInOut(duration: 0.3)) { proxy.scrollTo(new, anchor: .center) }
                }
            }
        }
    }
}

// MARK: - Playback Bar

struct QXPlaybackBar: View {
    let player: QXPlayerProtocol
    @State private var tick = 0

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(format(player.currentTime)).font(.caption.monospacedDigit()).foregroundColor(.secondary)
                Slider(value: Binding(get: { player.currentTime },
                    set: { player.seek(to: $0) }), in: 0...max(player.duration, 0.1))
                Text(format(player.duration)).font(.caption.monospacedDigit()).foregroundColor(.secondary)
            }.padding(.horizontal)
            HStack(spacing: 40) {
                Button { player.skipBackward() } label: {
                    Image(systemName: "gobackward.10").font(.title2) }.buttonStyle(.plain)
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 48)) }.buttonStyle(.plain)
                Button { player.skipForward() } label: {
                    Image(systemName: "goforward.10").font(.title2) }.buttonStyle(.plain)
            }
        }.padding(.horizontal, 16).padding(.vertical, 10).background(.regularMaterial)
    }

    private func format(_ t: TimeInterval) -> String {
        let m = Int(t) / 60, s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
