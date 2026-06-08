//
//  QXMainTabView.swift
//  QXMusicApp
//

import SwiftUI
import QXMusicInterface

struct QXMainTabView: View {
    var body: some View {
        TabView {
            QXLibraryPage()
                .tabItem { Label("乐谱库", systemImage: "music.note.list") }
            QXScanPage()
                .tabItem { Label("拍照识别", systemImage: "camera.viewfinder") }
            QXProfilePage()
                .tabItem { Label("我的", systemImage: "person.circle") }
        }
    }
}
