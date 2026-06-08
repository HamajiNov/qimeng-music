//
//  QXScoreProtocol.swift
//  QXMusicInterface
//

import Foundation
import LXAnnotation

/// 乐谱渲染协议 — 由 QXScoreKit 实现
public protocol QXScoreProtocol: LXAnnotationProtocol {
    /// 加载并渲染 MusicXML
    func loadMusicXML(url: URL)
    /// 跳转到指定时间（秒）
    func seekTo(seconds: TimeInterval)
    /// 获取当前播放时间
    var currentTime: TimeInterval { get }
    /// 播放状态变化回调
    var onPlaybackTimeChanged: ((TimeInterval) -> Void)? { get set }
}

/// 乐谱数据模型（跨模块共享）
public struct QXScoreItem: Codable {
    public let id: String
    public var title: String
    public var artist: String
    public let createdAt: Date
    public var isCached: Bool

    public init(id: String, title: String, artist: String, createdAt: Date, isCached: Bool) {
        self.id = id
        self.title = title
        self.artist = artist
        self.createdAt = createdAt
        self.isCached = isCached
    }
}
