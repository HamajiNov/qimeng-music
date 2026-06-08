import SwiftUI

/// 拍照识别 ViewModel
@MainActor
final class ScanViewModel: ObservableObject {
    enum State {
        case idle          // 初始：显示拍照/相册按钮
        case imageSelected(UIImage) // 已选图：裁剪/确认
        case uploading      // 上传中
        case waiting(String) // 等待识别，taskId
        case downloading    // 下载结果文件
        case completed(ScoreItem) // 完成
        case failed(String) // 失败，错误消息
    }

    @Published var state: State = .idle
    @Published var uploadProgress: Double = 0

    private var pollingTask: Task<Void, Never>?

    func selectImage(_ image: UIImage) {
        state = .imageSelected(image)
    }

    func startRecognition(image: UIImage) async {
        guard let imageData = image.jpegData(compressionQuality: 0.85) else {
            state = .failed("图片处理失败")
            return
        }

        state = .uploading

        do {
            // 1. 上传
            let response = try await APIClient.shared.uploadImage(imageData, filename: "score.jpg")
            let taskId = response.taskId

            // 2. 轮询
            state = .waiting(taskId)
            let taskResponse = try await pollTask(taskId: taskId)

            switch taskResponse.taskStatus {
            case .completed:
                guard let result = taskResponse.result else {
                    state = .failed("识别结果为空")
                    return
                }
                state = .downloading

                // 3. 下载文件
                let item = try await downloadResults(taskId: taskId, result: result)

                // 4. 添加到本地库
                try ScoreLibraryManager.addScore(
                    id: taskId,
                    title: result.title ?? "未知曲目",
                    artist: result.artist ?? "未知作者"
                )

                state = .completed(item)

            case .failed:
                state = .failed(taskResponse.error ?? "识别失败，请重试")
            default:
                state = .failed("未知错误")
            }

        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// 轮询任务状态（最多 5 分钟）
    private func pollTask(taskId: String) async throws -> TaskResponse {
        let maxAttempts = 300  // 5 分钟，每秒一次
        for _ in 0..<maxAttempts {
            let response = try await APIClient.shared.getTaskStatus(taskId)

            switch response.taskStatus {
            case .completed, .failed:
                return response
            case .processing:
                uploadProgress = Double(response.progress) / 100.0
                try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 秒
            case .pending:
                try await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
        throw APIError.timeout
    }

    /// 下载识别结果文件
    private func downloadResults(taskId: String, result: TaskResultData) async throws -> ScoreItem {
        let dir = try ScoreLibraryManager.prepareDirectory(for: taskId)
        let client = APIClient.shared

        // 并行下载
        async let musicxml: () = client.downloadFile(
            from: result.musicxmlUrl ?? "/api/v1/files/\(taskId)/score.musicxml",
            to: dir.appendingPathComponent("score.musicxml")
        )
        async let lrc: () = client.downloadFile(
            from: result.lrcUrl ?? "/api/v1/files/\(taskId)/lyrics.lrc",
            to: dir.appendingPathComponent("lyrics.lrc")
        )
        async let mp3: () = client.downloadFile(
            from: result.mp3Url ?? "/api/v1/files/\(taskId)/audio.mp3",
            to: dir.appendingPathComponent("audio.mp3")
        )

        _ = try await (musicxml, lrc, mp3)

        return ScoreItem(
            id: taskId,
            title: result.title ?? "未知曲目",
            artist: result.artist ?? "未知作者",
            createdAt: Date(),
            isCached: true
        )
    }

    func reset() {
        pollingTask?.cancel()
        pollingTask = nil
        state = .idle
        uploadProgress = 0
    }
}
