import Foundation

/// 乐谱清单条目（持久化于本地 manifest.json）
struct ScoreItem: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var artist: String
    var createdAt: Date
    var isCached: Bool

    /// 本地文件目录路径
    var localDirectory: URL {
        ScoreLibraryManager.scoresDirectory.appendingPathComponent(id)
    }

    var musicxmlURL: URL { localDirectory.appendingPathComponent("score.musicxml") }
    var lrcURL: URL { localDirectory.appendingPathComponent("lyrics.lrc") }
    var mp3URL: URL { localDirectory.appendingPathComponent("audio.mp3") }
}
