//
//  QXStorageProtocol.swift
//  QXMusicInterface
//

import Foundation
import LXAnnotation

/// 本地存储协议 — 由 QXMusicStore 实现
public protocol QXStorageProtocol: LXAnnotationProtocol {
    func loadScores() -> [QXScoreItem]
    func addScore(_ item: QXScoreItem) throws
    func removeScore(_ item: QXScoreItem) throws
    func prepareDirectory(for taskId: String) throws -> URL
    var cacheSizeFormatted: String { get }
    var scoresDirectory: URL { get }
}
