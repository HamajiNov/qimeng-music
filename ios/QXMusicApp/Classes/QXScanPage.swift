//
//  QXScanPage.swift
//  QXMusicApp
//

import SwiftUI
import PhotosUI
import LXAnnotation
import QXMusicInterface

struct QXScanPage: View {
    @State private var state: QXScanState = .idle
    @State private var progress: Double = 0
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var errorMessage: String?
    @State private var navigateToScore: QXScoreItem?

    var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .idle, .failed: idleView
                case .uploading, .waiting, .downloading: progressView
                default: EmptyView()
                }
            }
            .navigationTitle("拍照识别")
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { img in selectedImage = img; state = .idle }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let img = UIImage(data: data) {
                        await MainActor.run { selectedImage = img }
                    }
                }
            }
            .navigationDestination(item: $navigateToScore) { score in
                QXScoreDetailPage(score: score)
            }
        }
    }

    // MARK: - Idle / Image Preview

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            if let image = selectedImage ?? (state == .failed ? nil : nil) {
                // 已选图
                Image(uiImage: selectedImage!)
                    .resizable().scaledToFit().cornerRadius(12).padding(.horizontal)
                Text("确认使用此图片？").font(.headline)
                HStack(spacing: 24) {
                    Button("重新选择") { selectedImage = nil; errorMessage = nil }
                        .buttonStyle(.bordered)
                    Button("开始识别") { startRecognition() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                // 初始
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 80)).foregroundColor(.accentColor)
                Text("拍摄或选择乐谱照片").font(.title2)

                if let error = errorMessage {
                    Text(error).font(.callout).foregroundColor(.red).padding(.horizontal)
                    Button("重试") { errorMessage = nil }.buttonStyle(.bordered)
                }

                VStack(spacing: 16) {
                    Button { showCamera = true } label: {
                        Label("拍照", systemImage: "camera.fill").frame(maxWidth: 280)
                    }.buttonStyle(.borderedProminent).controlSize(.large)

                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("从相册选择", systemImage: "photo.on.rectangle").frame(maxWidth: 280)
                    }.buttonStyle(.bordered).controlSize(.large)
                }
            }

            Spacer()
        }
    }

    // MARK: - Progress

    private var progressView: some View {
        VStack(spacing: 24) {
            ProgressView(value: progress, total: 1.0).padding(.horizontal, 48)
            Text(statusMessage).foregroundColor(.secondary).multilineTextAlignment(.center)
            Button("取消") { reset() }.foregroundColor(.red)
        }
    }

    private var statusMessage: String {
        switch state {
        case .uploading: return "正在上传图片..."
        case .waiting(let id): return "正在识别乐谱...\n\(id.prefix(8))..."
        case .downloading: return "正在下载结果..."
        default: return ""
        }
    }

    // MARK: - Actions

    private func startRecognition() {
        guard let img = selectedImage,
              let data = img.jpegData(compressionQuality: 0.85) else { return }

        guard let scanner = LXAnnotation.getInstance(
            forProtocolType: QXScanProtocol.self) as? QXScanProtocol else { return }

        scanner.onStateChanged = {
            DispatchQueue.main.async {
                self.state = scanner.state
                self.progress = scanner.progress
                if case .completed(let item) = scanner.state {
                    self.navigateToScore = item
                    self.reset()
                }
                if case .failed(let msg) = scanner.state {
                    self.errorMessage = msg
                    self.state = .idle
                }
            }
        }

        state = .uploading
        Task { try? await scanner.recognize(imageData: data) }
    }

    private func reset() {
        guard let scanner = LXAnnotation.getInstance(
            forProtocolType: QXScanProtocol.self) as? QXScanProtocol else { return }
        scanner.onStateChanged = nil
        selectedImage = nil
        state = .idle
        progress = 0
    }
}

// MARK: - Camera Picker

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = sourceType
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ ui: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }
        func imagePickerController(_ p: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { onPick(img) }
            p.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ p: UIImagePickerController) { p.dismiss(animated: true) }
    }
}
