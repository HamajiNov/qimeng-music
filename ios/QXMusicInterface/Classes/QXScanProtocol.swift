//
//  QXScanProtocol.swift
//  QXMusicInterface
//

import Foundation
import LXAnnotation

/// 扫描识别协议 — 由 QXScanKit 实现
public protocol QXScanProtocol: LXAnnotationProtocol {
    /// 上传图片并等待识别完成
    func recognize(imageData: Data) async throws -> QXRecognizeResult
    /// 当前状态
    var state: QXScanState { get }
    /// 上传进度 (0.0~1.0)
    var progress: Double { get }
    /// 状态变化回调
    var onStateChanged: (() -> Void)? { get set }
}

public enum QXScanState {
    case idle
    case uploading
    case waiting(taskId: String)
    case downloading
    case completed(QXScoreItem)
    case failed(String)
}

/// 服务端识别结果
public struct QXRecognizeResult: Codable {
    public let taskId: String
    public let title: String?
    public let artist: String?
    public let pageCount: Int?
    public let musicxmlUrl: String?
    public let lrcUrl: String?
    public let mp3Url: String?

    public init(taskId: String, title: String?, artist: String?, pageCount: Int?, musicxmlUrl: String?, lrcUrl: String?, mp3Url: String?) {
        self.taskId = taskId
        self.title = title
        self.artist = artist
        self.pageCount = pageCount
        self.musicxmlUrl = musicxmlUrl
        self.lrcUrl = lrcUrl
        self.mp3Url = mp3Url
    }
}
