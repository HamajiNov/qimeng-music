//
//  QXRecognitionAPIProtocol.swift
//  QXMusicInterface
//

import Foundation
import LXAnnotation

/// 远程识别 API 协议 — 由 QXMusicStore 实现
public protocol QXRecognitionAPIProtocol: LXAnnotationProtocol {
    func uploadImage(_ imageData: Data, filename: String) async throws -> (taskId: String, status: String)
    func pollTask(_ taskId: String) async throws -> (status: String, result: QXRecognizeResult?)
    func downloadFile(from path: String, to localURL: URL) async throws
}

public enum QXAPIError: Error, LocalizedError {
    case serverError(String)
    case timeout

    public var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        case .timeout:
            return "请求超时"
        }
    }
}
