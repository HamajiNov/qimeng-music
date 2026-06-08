import SwiftUI

/// 设置页
struct ProfilePage: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var showClearConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // 存储信息
                Section("存储") {
                    HStack {
                        Text("缓存大小")
                        Spacer()
                        Text(viewModel.cacheSizeFormatted)
                            .foregroundColor(.secondary)
                    }

                    Button("清除所有缓存", role: .destructive) {
                        showClearConfirmation = true
                    }
                }

                // 关于
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("应用名称")
                        Spacer()
                        Text("启蒙乐谱")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("我的")
            .onAppear { viewModel.loadScores() }
            .alert("确认清除", isPresented: $showClearConfirmation) {
                Button("取消", role: .cancel) {}
                Button("确认清除", role: .destructive) {
                    for score in viewModel.scores {
                        viewModel.deleteScore(score)
                    }
                }
            } message: {
                Text("将删除所有已下载的乐谱和音频文件，此操作不可撤销。")
            }
        }
    }
}
