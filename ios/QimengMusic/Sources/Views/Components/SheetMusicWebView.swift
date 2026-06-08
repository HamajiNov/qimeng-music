import SwiftUI
import WebKit

/// 通过 WKWebView 加载 alphaTab 渲染 MusicXML
struct SheetMusicWebView: UIViewRepresentable {
    let musicxmlURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        config.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.minimumZoomScale = 0.5
        webView.scrollView.maximumZoomScale = 3.0

        // 加载 alphaTab HTML
        let html = buildAlphaTabHTML(musicxml: try? String(contentsOf: musicxmlURL, encoding: .utf8))
        webView.loadHTMLString(html, baseURL: nil)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    /// 构造内嵌 alphaTab 的 HTML
    private func buildAlphaTabHTML(musicxml: String?) -> String {
        let escapedXML = musicxml?
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")
            ?? ""

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0">
        <script src="https://cdn.jsdelivr.net/npm/@coderline/alphatab@1.3/dist/alphaTab.min.js"></script>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { background: #fff; }
          #sheet { width: 100%; }
          @media (prefers-color-scheme: dark) {
            body { background: #1c1c1e; }
            #sheet { filter: invert(1) hue-rotate(180deg); }
          }
        </style>
        </head>
        <body>
        <div id="sheet"></div>
        <script>
        const api = new alphaTab.AlphaTabApi(document.getElementById("sheet"), {
          core: { file: null },
          display: {
            layoutMode: "page",
            staveProfile: "default",
            resources: { lyricsFont: "'PingFang SC', sans-serif" }
          },
          player: { enablePlayer: true, enableCursor: true, soundFont: null },
        });

        const musicxml = `\(escapedXML)`;
        if (musicxml) {
          api.load(musicxml, [0, 1]);
        } else {
          document.getElementById("sheet").innerHTML =
            "<div style='padding:40px;text-align:center;color:#999;'>无法加载乐谱</div>";
        }
        </script>
        </body>
        </html>
        """
    }
}
