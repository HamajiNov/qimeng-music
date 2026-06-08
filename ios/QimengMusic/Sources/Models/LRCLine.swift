import Foundation

/// 单行 LRC 歌词
struct LRCLine: Identifiable {
    let id = UUID()
    let timestamp: TimeInterval  // 秒
    let text: String
}
