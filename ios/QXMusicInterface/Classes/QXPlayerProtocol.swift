//
//  QXPlayerProtocol.swift
//  QXMusicInterface
//

import Foundation
import LXAnnotation

/// 播放器协议 — 由 QXPlayerKit 实现
public protocol QXPlayerProtocol: LXAnnotationProtocol {
    /// 加载乐谱并准备播放
    func load(score: QXScoreItem) async
    /// 播放/暂停
    func togglePlayPause()
    /// 跳转到指定时间
    func seek(to time: TimeInterval)
    /// 快退
    func skipBackward(_ seconds: TimeInterval)
    /// 快进
    func skipForward(_ seconds: TimeInterval)
    /// 停止并释放资源
    func stop()

    var isPlaying: Bool { get }
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var currentLyricIndex: Int { get }
    var lyrics: [QXLRCLine] { get }
    var isLoading: Bool { get }

    /// 状态变化回调（UI 绑定）
    var onStateChanged: (() -> Void)? { get set }
}

/// LRC 歌词行
public struct QXLRCLine: Identifiable, Sendable {
    public let id = UUID()
    public let timestamp: TimeInterval
    public let text: String

    public init(timestamp: TimeInterval, text: String) {
        self.timestamp = timestamp
        self.text = text
    }
}
