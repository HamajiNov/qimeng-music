//
//  QXAPIClient.swift
//  QXMusicStore
//

import Foundation
import LXProtocol
import LXAnnotation
import QXMusicInterface

/// API 客户端 — 封装与服务端的 HTTP 通信
public final class QXAPIClient {
    public static let shared = QXAPIClient()

    private var baseURL: String {
        UserDefaults.standard.string(forKey: "api_base_url") ?? "http://localhost:8000"
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 600
        return URLSession(configuration: config)
    }()

    // MARK: - Recognize

    public func uploadImage(_ imageData: Data, filename: String) async throws -> (taskId: String, status: String) {
        var request = try makeRequest("POST", "/api/v1/recognize")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createMultipartBody(data: imageData, filename: filename, boundary: boundary)

        let data = try await perform(request)
        let json = try JSONDecoder().decode([String: String].self, from: data)
        return (taskId: json["task_id"] ?? "", status: json["status"] ?? "")
    }

    // MARK: - Poll

    public func pollTask(_ taskId: String) async throws -> (status: String, result: QXRecognizeResult?) {
        let request = try makeRequest("GET", "/api/v1/tasks/\(taskId)")
        let data = try await perform(request)

        struct TaskJSON: Codable {
            let status: String
            let progress: Int?
            let result: QXRecognizeResult?
            let error: String?
        }
        let json = try JSONDecoder().decode(TaskJSON.self, from: data)

        if json.status == "failed" { throw APIError.serverError(json.error ?? "识别失败") }
        return (json.status, json.result)
    }

    // MARK: - Download

    public func downloadFile(from path: String, to localURL: URL) async throws {
        let request = try makeRequest("GET", path)
        let (data, _) = try await session.data(for: request)
        try data.write(to: localURL)
    }

    // MARK: - Helpers

    private var apiBase: URL { URL(string: baseURL)! }

    private func makeRequest(_ method: String, _ path: String) throws -> URLRequest {
        var req = URLRequest(url: apiBase.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return req
    }

    private func perform(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError("请求失败")
        }
        return data
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

public enum APIError: Error, LocalizedError {
    case serverError(String)
    case timeout
    public var errorDescription: String? {
        switch self {
        case .serverError(let msg): return msg
        case .timeout: return "请求超时"
        }
    }
}
