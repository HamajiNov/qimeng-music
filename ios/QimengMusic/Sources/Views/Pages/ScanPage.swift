import SwiftUI
import PhotosUI

/// 拍照识别页
struct ScanPage: View {
    @StateObject private var viewModel = ScanViewModel()
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    idleView
                case .imageSelected(let image):
                    previewView(image: image)
                case .uploading:
                    progressView(message: "正在上传图片...", progress: viewModel.uploadProgress)
                case .waiting(let taskId):
                    progressView(message: "正在识别乐谱...\n\(taskId.prefix(8))...", progress: viewModel.uploadProgress)
                case .downloading:
                    progressView(message: "正在下载结果...", progress: 0.9)
                case .completed:
                    Text("") // 由外部导航处理
                case .failed(let error):
                    errorView(message: error)
                }
            }
            .navigationTitle("拍照识别")
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in
                    viewModel.selectImage(image)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        await MainActor.run { viewModel.selectImage(image) }
                    }
                }
            }
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "camera.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("拍摄或选择乐谱照片")
                .font(.title2)
                .foregroundColor(.primary)

            VStack(spacing: 16) {
                Button {
                    showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }

            Spacer()
        }
    }

    // MARK: - Preview

    private func previewView(image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .cornerRadius(12)
                .padding(.horizontal)

            Text("确认使用此图片？")
                .font(.headline)

            HStack(spacing: 24) {
                Button("重新选择") {
                    viewModel.reset()
                }
                .buttonStyle(.bordered)

                Button("开始识别") {
                    Task { await viewModel.startRecognition(image: image) }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Progress

    private func progressView(message: String, progress: Double) -> some View {
        VStack(spacing: 24) {
            ProgressView(value: progress, total: 1.0)
                .progressViewStyle(.linear)
                .padding(.horizontal, 48)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("取消") {
                viewModel.reset()
            }
            .foregroundColor(.red)
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("识别失败")
                .font(.title3)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("重新识别") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

// MARK: - Camera Wrapper

private struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let onPick: (UIImage) -> Void
        init(onPick: @escaping (UIImage) -> Void) { self.onPick = onPick }

        func imagePickerController(_ picker: UIImagePickerController,
                                    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onPick(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
