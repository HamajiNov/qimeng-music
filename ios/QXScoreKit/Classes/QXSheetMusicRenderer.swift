//
//  QXSheetMusicRenderer.swift
//  QXScoreKit
//

import SwiftUI
import WebKit
import LXProtocol
import LXAnnotation
import QXMusicInterface

/// alphaTab 乐谱渲染器 — 实现 QXScoreProtocol
final class QXSheetMusicRenderer: NSObject, QXScoreProtocol {
    private var webView: WKWebView?
    var onPlaybackTimeChanged: ((TimeInterval) -> Void)?
    var currentTime: TimeInterval = 0

    func makeWebView() -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.isOpaque = false
        wv.backgroundColor = .clear
        #if os(iOS)
        wv.scrollView.minimumZoomScale = 0.5
        wv.scrollView.maximumZoomScale = 3.0
        #endif
        self.webView = wv
        return wv
    }

    func loadMusicXML(url: URL) {
        let xml = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        let html = buildHTML(musicxml: xml)
        webView?.loadHTMLString(html, baseURL: nil)
    }

    func seekTo(seconds: TimeInterval) {
        currentTime = seconds
        // JS bridge: alphaTab seek
        let js = "if(window.api) window.api.playbackController?.seekTo(\(seconds * 1000), false)"
        webView?.evaluateJavaScript(js)
    }

    private func buildHTML(musicxml: String) -> String {
        let escaped = musicxml
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        return """
        <!DOCTYPE html><html><head>
        <meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=3.0">
        <script src="https://cdn.jsdelivr.net/npm/@coderline/alphatab@1.3/dist/alphaTab.min.js"></script>
        <style>*{margin:0;padding:0}body{background:#fff}
        @media(prefers-color-scheme:dark){body{background:#1c1c1e}#sheet{filter:invert(1)hue-rotate(180deg)}}</style>
        </head><body><div id="sheet"></div><script>
        window.api=new alphaTab.AlphaTabApi(document.getElementById("sheet"),{
          core:{file:null},
          display:{layoutMode:"page",staveProfile:"default",
            resources:{lyricsFont:"'PingFang SC',sans-serif"}},
          player:{enablePlayer:true,enableCursor:true,soundFont:null}
        });
        const xml=`\(escaped)`;
        if(xml)window.api.load(xml,[0,1]);
        else document.getElementById("sheet").innerHTML=
          "<div style='padding:40px;text-align:center;color:#999;'>无法加载乐谱</div>";
        </script></body></html>
        """
    }
}

// MARK: - SwiftUI Wrapper

struct QXSheetMusicView: UIViewRepresentable {
    let renderer: QXSheetMusicRenderer

    func makeUIView(context: Context) -> WKWebView {
        renderer.makeWebView()
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// MARK: - LXProtocol 模块注册

@objc class QXScoreKitModule: NSObject, LXProtocol {
    @objc class func swift_priority() -> LXPriority { LXPriorityMedium }
    @objc class func swift_load() {
        LXAnnotation.register(
            instance: QXSheetMusicRenderer(),
            forProtocolType: QXScoreProtocol.self
        )
    }
}
