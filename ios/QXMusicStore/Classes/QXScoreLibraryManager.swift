//
//  QXScoreLibraryManager.swift
//  QXMusicStore
//

import Foundation
import LXProtocol
import LXAnnotation
import QXMusicInterface

/// 本地乐谱库管理器 — 实现 QXStorageProtocol
actor QXScoreLibraryManager {
    static let shared = QXScoreLibraryManager()

    private lazy var scoresDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("qxscores")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private var manifestURL: URL {
        scoresDirectory.appendingPathComponent("manifest.json")
    }
}

// MARK: - QXStorageProtocol

extension QXScoreLibraryManager: QXStorageProtocol {
    nonisolated var scoresDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("qxscores")
    }

    func loadScores() -> [QXScoreItem] {
        guard let data = try? Data(contentsOf: manifestURL),
              let items = try? JSONDecoder().decode([QXScoreItem].self, from: data) else {
            return []
        }
        return items.map { item in
            var copy = item
            let mp3URL = scoresDirectory.appendingPathComponent(item.id).appendingPathComponent("audio.mp3")
            copy.isCached = FileManager.default.fileExists(atPath: mp3URL.path)
            return copy
        }
    }

    func addScore(_ item: QXScoreItem) throws {
        var items = loadScores()
        items.removeAll { $0.id == item.id }
        items.insert(item, at: 0)
        let data = try JSONEncoder().encode(items)
        try data.write(to: manifestURL)
    }

    func removeScore(_ item: QXScoreItem) throws {
        let dir = scoresDirectory.appendingPathComponent(item.id)
        try? FileManager.default.removeItem(at: dir)
        var items = loadScores()
        items.removeAll { $0.id == item.id }
        let data = try JSONEncoder().encode(items)
        try data.write(to: manifestURL)
    }

    func prepareDirectory(for taskId: String) throws -> URL {
        let dir = scoresDirectory.appendingPathComponent(taskId)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    nonisolated var cacheSizeFormatted: String {
        let bytes = cacheSize()
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }

    private func cacheSize() -> Int64 {
        guard let enumerator = FileManager.default.enumerator(
            at: scoresDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }
        var total: Int64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

// MARK: - LXProtocol 模块注册

@objc class QXMusicStoreModule: NSObject, LXProtocol {
    @objc class func swift_priority() -> LXPriority { LXPriorityMedium }
    @objc class func swift_load() {
        LXAnnotation.register(
            instance: QXScoreLibraryManager.shared,
            forProtocolType: QXStorageProtocol.self
        )
    }
}
