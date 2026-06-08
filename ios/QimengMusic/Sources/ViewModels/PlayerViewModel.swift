import SwiftUI
import AVFoundation

/// KTV 播放器 ViewModel — 管理 MP3 播放 + LRC 歌词同步
@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentLyricIndex: Int = 0
    @Published var lyrics: [LRCLine] = []
    @Published var isLoading = true

    private var player: AVPlayer?
    private var timeObserver: Any?

    // MARK: - Load

    func load(score: ScoreItem) async {
        isLoading = true

        // 加载 LRC
        if let lrcText = try? String(contentsOf: score.lrcURL, encoding: .utf8) {
            lyrics = LRCParser.parse(lrcText)
        }

        // 加载 MP3
        let playerItem = AVPlayerItem(url: score.mp3URL)
        player = AVPlayer(playerItem: playerItem)

        // 获取时长
        if let cmDuration = try? await playerItem.asset.load(.duration) {
            duration = CMTimeGetSeconds(cmDuration)
        }

        // 时间观察器 — 每 0.1 秒更新
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let secs = CMTimeGetSeconds(time)
            self.currentTime = secs
            self.updateLyricIndex(for: secs)
        }

        isLoading = false
    }

    // MARK: - Playback Control

    func togglePlayPause() {
        guard let player else { return }
        if player.rate > 0 {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        currentTime = time
    }

    func skipBackward(_ seconds: TimeInterval = 10) {
        seek(to: max(0, currentTime - seconds))
    }

    func skipForward(_ seconds: TimeInterval = 10) {
        seek(to: min(duration, currentTime + seconds))
    }

    // MARK: - Lyrics Sync

    private func updateLyricIndex(for time: TimeInterval) {
        guard !lyrics.isEmpty else { return }
        // 二分查找当前歌词行
        var lo = 0, hi = lyrics.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if lyrics[mid].timestamp <= time {
                lo = mid
            } else {
                hi = mid - 1
            }
        }
        if lyrics[lo].timestamp <= time {
            currentLyricIndex = lo
        }
    }

    // MARK: - Cleanup

    func stop() {
        player?.pause()
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        timeObserver = nil
        player = nil
        isPlaying = false
    }

    var formattedCurrentTime: String {
        formatTime(currentTime)
    }

    var formattedDuration: String {
        formatTime(duration)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60
        let s = Int(t) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
