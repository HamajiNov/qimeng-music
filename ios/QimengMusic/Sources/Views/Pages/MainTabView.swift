import SwiftUI

/// 主标签页
struct MainTabView: View {
    var body: some View {
        TabView {
            LibraryPage()
                .tabItem {
                    Label("乐谱库", systemImage: "music.note.list")
                }

            ScanPage()
                .tabItem {
                    Label("拍照识别", systemImage: "camera.viewfinder")
                }

            ProfilePage()
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
    }
}
