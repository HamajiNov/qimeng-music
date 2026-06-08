//
//  QXPlayerManager.swift
//  QXPlayerKit
//

import AVFoundation
import LXProtocol
import LXAnnotation
import QXMusicInterface
import QXMusicStore

/// KTV 播放器 — 实现 QXPlayerProtocol
final class QXPlayerManager: NSObject, ObservableObject, QXPlayerProtocol {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentLyricIndex: Int = 0
    @Published var lyrics: [QXLRCLine] = []
    @Published var isLoading = false

    public var onStateChanged: (() -> Void)?

    private var player: AVPlayer?
    private var timeObserver: Any?

    public func load(score: QXScoreItem) async {
        isLoading = true

        // 加载 LRC
        let lrcURL = QXScoreLibraryManager.shared.scoresDirectory
            .appendingPathComponent(score.id).appendingPathComponent("lyrics.lrc")
        if let lrcText = try? String(contentsOf: lrcURL, encoding: .utf8) {
            lyrics = QXLRCParser.parse(lrcText)
        }

        // 加载 MP3
        let mp3URL = QXScoreLibraryManager.shared.scoresDirectory
            .appendingPathComponent(score.id).appendingPathComponent("audio.mp3")
        let item = AVPlayerItem(url: mp3URL)
        player = AVPlayer(playerItem: item)

        if let cmDuration = try? await item.asset.load(.duration) {
            duration = CMTimeGetSeconds(cmDuration)
        }

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self else { return }
            let secs = CMTimeGetSeconds(t)
            self.currentTime = secs
            self.updateLyricIndex(for: secs)
            self.onStateChanged?()
        }

        isLoading = false
        onStateChanged?()
    }

    public func togglePlayPause() {
        guard let player else { return }
        if player.rate > 0 { player.pause(); isPlaying = false }
        else { player.play(); isPlaying = true }
        onStateChanged?()
    }

    public func seek(to time: TimeInterval) {
        let cm = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cm)
        currentTime = time
    }

    public func skipBackward(_ seconds: TimeInterval = 10) { seek(to: max(0, currentTime - seconds)) }
    public func skipForward(_ seconds: TimeInterval = 10) { seek(to: min(duration, currentTime + seconds)) }

    public func stop() {
        player?.pause()
        if let obs = timeObserver { player?.removeTimeObserver(obs) }
        timeObserver = nil; player = nil; isPlaying = false
    }

    private func updateLyricIndex(for time: TimeInterval) {
        guard !lyrics.isEmpty else { return }
        var lo = 0, hi = lyrics.count - 1
        while lo < hi {
            let mid = (lo + hi + 1) / 2
            if lyrics[mid].timestamp <= time { lo = mid } else { hi = mid - 1 }
        }
        if lyrics[lo].timestamp <= time { currentLyricIndex = lo }
    }

    public var formattedCurrentTime: String {
        let m = Int(currentTime) / 60, s = Int(currentTime) % 60
        return String(format: "%02d:%02d", m, s)
    }
    public var formattedDuration: String {
        let m = Int(duration) / 60, s = Int(duration) % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - LRC Parser

public enum QXLRCParser {
    public static func parse(_ content: String) -> [QXLRCLine] {
        var lines: [QXLRCLine] = []
        for raw in content.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespaces)
            guard line.contains("[") && line.contains("]") else { continue }
            guard let closeBracket = line.firstIndex(of: "]") else { continue }
            let timeStr = String(line[line.index(after: line.startIndex)..<closeBracket])
            let parts = timeStr.components(separatedBy: ":")
            guard parts.count == 2, let min = Double(parts[0]), let sec = Double(parts[1]) else { continue }
            let text = String(line[line.index(after: closeBracket)...])
            lines.append(QXLRCLine(timestamp: min * 60 + sec, text: text))
        }
        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}

// MARK: - LXProtocol 模块注册

@objc class QXPlayerKitModule: NSObject, LXProtocol {
    @objc class func swift_priority() -> LXPriority { LXPriorityMedium }
    @objc class func swift_load() {
        LXAnnotation.register(
            instance: QXPlayerManager(),
            forProtocolType: QXPlayerProtocol.self
        )
    }
}
