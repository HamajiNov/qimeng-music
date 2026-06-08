import Foundation

/// LRC 歌词解析器
enum LRCParser {
    /// 解析 LRC 文本为 [LRCLine]
    static func parse(_ lrcContent: String) -> [LRCLine] {
        var lines: [LRCLine] = []
        let pattern = /^\[(\d{2}):(\d{2})\.(\d{2,3})\](.+)$/

        for line in lrcContent.components(separatedBy: .newlines) {
            guard let match = try? pattern.wholeMatch(in: line.trimmingCharacters(in: .whitespaces)) else {
                continue
            }
            let minutes = Double(match.1) ?? 0
            let seconds = Double(match.2) ?? 0
            let centiseconds = (Double(match.3) ?? 0) / (match.3.count == 3 ? 1000.0 : 100.0)
            let timestamp = minutes * 60 + seconds + centiseconds
            let text = String(match.4).trimmingCharacters(in: .whitespaces)
            lines.append(LRCLine(timestamp: timestamp, text: text))
        }

        return lines.sorted { $0.timestamp < $1.timestamp }
    }
}
