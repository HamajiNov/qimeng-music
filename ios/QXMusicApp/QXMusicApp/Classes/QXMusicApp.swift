//
//  QXMusicApp.swift
//  QXMusicApp
//

import SwiftUI
import LXProtocol
import QXMusicInterface

@main
struct QXMusicApp: App {
    init() {
        _ = UIApplication.runOnce // 触发 LXProtocol 自发现
    }

    var body: some Scene {
        WindowGroup {
            QXMainTabView()
        }
    }
}
