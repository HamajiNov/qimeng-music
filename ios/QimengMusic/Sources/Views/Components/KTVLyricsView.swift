import SwiftUI

/// KTV 风格歌词视图：自动滚动 + 当前行高亮
struct KTVLyricsView: View {
    let lyrics: [LRCLine]
    let currentIndex: Int

    var body: some View {
        if lyrics.isEmpty {
            VStack {
                Image(systemName: "text.alignleft")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("无歌词")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        } else {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        // 顶部留白，让首行可以滚动到中间
                        Color.clear.frame(height: 60)

                        ForEach(Array(lyrics.enumerated()), id: \.element.id) { index, line in
                            LyricLineView(
                                text: line.text,
                                isActive: index == currentIndex
                            )
                            .id(index)
                        }

                        // 底部留白
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, 32)
                }
                .onChange(of: currentIndex) { _, newIndex in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
    }
}

// MARK: - Single Lyric Line

private struct LyricLineView: View {
    let text: String
    let isActive: Bool

    var body: some View {
        Text(text)
            .font(isActive ? .title3.weight(.bold) : .body)
            .foregroundColor(isActive ? .primary : .secondary.opacity(0.5))
            .scaleEffect(isActive ? 1.1 : 0.95)
            .animation(.easeInOut(duration: 0.3), value: isActive)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}
