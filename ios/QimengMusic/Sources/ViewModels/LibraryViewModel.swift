import SwiftUI

/// 乐谱库列表 ViewModel
@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var scores: [ScoreItem] = []
    @Published var isLoading = false

    func loadScores() {
        isLoading = true
        scores = ScoreLibraryManager.loadManifest()
        isLoading = false
    }

    func deleteScore(_ item: ScoreItem) {
        do {
            try ScoreLibraryManager.removeScore(item)
            scores.removeAll { $0.id == item.id }
        } catch {
            print("删除乐谱失败: \(error)")
        }
    }

    var cacheSizeFormatted: String {
        let bytes = ScoreLibraryManager.cacheSize()
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
