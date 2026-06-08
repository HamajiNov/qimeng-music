import Foundation

/// API 客户端，封装与服务端的 HTTP 通信
actor APIClient {
    static let shared = APIClient()

    /// 服务端地址（部署后修改）
    private var baseURL: String {
        // TODO: 替换为实际服务器地址
        UserDefaults.standard.string(forKey: "api_base_url") ?? "http://localhost:8000"
    }

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 600
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Recognize

    /// 上传图片，启动 OMR 识别
    func uploadImage(_ imageData: Data, filename: String) async throws -> TaskCreatedResponse {
        var request = try makeRequest("POST", "/api/v1/recognize")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartBody(data: imageData, filename: filename, boundary: boundary)

        return try await perform(request)
    }

    // MARK: - Task Polling

    /// 轮询任务状态
    func getTaskStatus(_ taskId: String) async throws -> TaskResponse {
        let request = try makeRequest("GET", "/api/v1/tasks/\(taskId)")
        return try await perform(request)
    }

    // MARK: - Render

    /// 提交 MusicXML 渲染 MP3
    func renderMusicXML(_ musicxml: String) async throws -> TaskCreatedResponse {
        var request = try makeRequest("POST", "/api/v1/render")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RenderRequest(musicxml: musicxml))
        return try await perform(request)
    }

    // MARK: - Download

    /// 下载文件到本地目录
    func downloadFile(from path: String, to localURL: URL) async throws {
        let request = try makeRequest("GET", path)
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw APIError.serverError("下载失败")
        }
        try data.write(to: localURL)
    }

    // MARK: - Helpers

    private var apiBase: URL {
        URL(string: baseURL)!
    }

    private func makeRequest(_ method: String, _ path: String) throws -> URLRequest {
        let url = apiBase.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError("HTTP \(httpResponse.statusCode)")
        }

        return try decoder.decode(T.self, from: data)
    }

    private func createMultipartBody(data: Data, filename: String, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case invalidResponse
    case serverError(String)
    case networkError(Error)
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "服务端无响应"
        case .serverError(let msg): return msg
        case .networkError(let err): return err.localizedDescription
        case .timeout: return "请求超时，请稍后重试"
        }
    }
}
