import Foundation

/// 服务端返回的任务状态
enum TaskStatus: String, Codable {
    case pending
    case processing
    case completed
    case failed
}

/// POST /recognize 或 /render 的响应
struct TaskCreatedResponse: Codable {
    let taskId: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case status
    }
}

/// 任务完成后的结果
struct TaskResultData: Codable {
    let title: String?
    let artist: String?
    let pageCount: Int?
    let musicxmlUrl: String?
    let lrcUrl: String?
    let mp3Url: String?

    enum CodingKeys: String, CodingKey {
        case title, artist
        case pageCount = "page_count"
        case musicxmlUrl = "musicxml_url"
        case lrcUrl = "lrc_url"
        case mp3Url = "mp3_url"
    }
}

/// GET /tasks/{id} 的响应
struct TaskResponse: Codable {
    let taskId: String
    let type: String
    let status: String
    let progress: Int
    let result: TaskResultData?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case taskId = "task_id"
        case type, status, progress, result, error
    }

    var taskStatus: TaskStatus {
        TaskStatus(rawValue: status) ?? .pending
    }
}

/// POST /render 的请求体
struct RenderRequest: Codable {
    let musicxml: String
}
