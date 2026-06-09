//
//  QXScanManager.swift
//  QXScanKit
//

import Foundation
import LXProtocol
import LXAnnotation
import QXMusicInterface

/// 扫描识别管理器 — 实现 QXScanProtocol
final class QXScanManager: QXScanProtocol {
    var state: QXScanState = .idle
    var progress: Double = 0
    public var onStateChanged: (() -> Void)?

    public func recognize(imageData: Data) async throws -> QXRecognizeResult {
        guard let storage = LXAnnotation.getInstance(
            forProtocolType: QXStorageProtocol.self
        ) as? QXStorageProtocol else {
            throw QXAPIError.serverError("本地存储服务未注册")
        }
        guard let client = LXAnnotation.getInstance(
            forProtocolType: QXRecognitionAPIProtocol.self
        ) as? QXRecognitionAPIProtocol else {
            throw QXAPIError.serverError("远程识别服务未注册")
        }

        state = .uploading; onStateChanged?()

        let (taskId, _) = try await client.uploadImage(imageData, filename: "score.jpg")

        state = .waiting(taskId: taskId); onStateChanged?()

        // 轮询，最多 5 分钟
        for _ in 0..<300 {
            let (status, result) = try await client.pollTask(taskId)

            switch status {
            case "completed":
                guard let result else { throw QXAPIError.serverError("结果为空") }
                state = .downloading; onStateChanged?()

                // 下载文件
                let dir = try storage.prepareDirectory(for: taskId)
                if let musicxmlUrl = result.musicxmlUrl {
                    try await client.downloadFile(from: musicxmlUrl, to: dir.appendingPathComponent("score.musicxml"))
                }
                if let lrcUrl = result.lrcUrl {
                    try await client.downloadFile(from: lrcUrl, to: dir.appendingPathComponent("lyrics.lrc"))
                }
                if let mp3Url = result.mp3Url {
                    try await client.downloadFile(from: mp3Url, to: dir.appendingPathComponent("audio.mp3"))
                }

                let item = QXScoreItem(
                    id: taskId, title: result.title ?? "未知曲目",
                    artist: result.artist ?? "未知作者",
                    createdAt: Date(), isCached: true
                )
                try storage.addScore(item)

                state = .completed(item); onStateChanged?()
                return result

            case "processing":
                progress = 0.5
            default:
                break
            }
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        }

        state = .failed("超时"); onStateChanged?()
        throw QXAPIError.timeout
    }

    public func reset() { state = .idle; progress = 0; onStateChanged?() }
}

// MARK: - LXProtocol 模块注册

@objc class QXScanKitModule: NSObject, LXProtocol {
    @objc class func swift_priority() -> LXPriority { LXPriorityMedium }
    @objc class func swift_load() {
        LXAnnotation.register(
            instance: QXScanManager(),
            forProtocolType: QXScanProtocol.self
        )
    }
}
