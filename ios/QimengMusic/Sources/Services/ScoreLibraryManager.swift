import Foundation

/// 本地乐谱库管理：缓存、清单维护
actor ScoreLibraryManager {
    static let scoresDirectory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("scores")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private static var manifestURL: URL {
        scoresDirectory.appendingPathComponent("manifest.json")
    }

    /// 读取乐谱清单
    static func loadManifest() -> [ScoreItem] {
        guard let data = try? Data(contentsOf: manifestURL),
              let items = try? JSONDecoder().decode([ScoreItem].self, from: data) else {
            return []
        }
        // 更新缓存状态
        return items.map { item in
            var copy = item
            copy.isCached = FileManager.default.fileExists(atPath: item.mp3URL.path)
            return copy
        }
    }

    /// 保存乐谱清单
    static func saveManifest(_ items: [ScoreItem]) throws {
        let data = try JSONEncoder().encode(items)
        try data.write(to: manifestURL)
    }

    /// 添加一份乐谱到库
    static func addScore(id: String, title: String, artist: String) throws {
        var items = loadManifest()
        // 去重
        items.removeAll { $0.id == id }
        let item = ScoreItem(
            id: id,
            title: title,
            artist: artist,
            createdAt: Date(),
            isCached: true
        )
        items.insert(item, at: 0)
        try saveManifest(items)
    }

    /// 删除本地缓存
    static func removeScore(_ item: ScoreItem) throws {
        // 删除文件
        try? FileManager.default.removeItem(at: item.localDirectory)
        // 更新清单
        var items = loadManifest()
        items.removeAll { $0.id == item.id }
        try saveManifest(items)
    }

    /// 总缓存大小（字节）
    static func cacheSize() -> Int64 {
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

    /// 创建本地目录
    static func prepareDirectory(for taskId: String) throws -> URL {
        let dir = scoresDirectory.appendingPathComponent(taskId)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
