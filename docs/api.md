# API 文档

> Base URL: `http://<server>:8000/api/v1`

## 端点一览

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/health` | 健康检查 | 无 |
| POST | `/recognize` | 上传乐谱图片，启动 OMR 识别 | 无 |
| GET | `/tasks/{task_id}` | 查询识别/渲染任务状态 | 无 |
| POST | `/render` | 提交 MusicXML，启动音频渲染 | 无 |
| GET | `/files/{file_id}/{filename}` | 下载生成的文件 | 无 |

---

## POST /recognize

上传乐谱图片，启动异步 OMR 识别任务。

### Request
```
POST /api/v1/recognize
Content-Type: multipart/form-data
Body:
  image: <binary> (jpg/png, max 10MB)
```

### Response
```
HTTP 202 Accepted
{
    "task_id": "a1b2c3d4-...",
    "status": "pending"
}
```

### Error
```
HTTP 400 Bad Request
{
    "detail": "不支持的文件格式"
}
```

---

## GET /tasks/{task_id}

查询任务状态。

### Request
```
GET /api/v1/tasks/a1b2c3d4-...
```

### Response (处理中)
```
HTTP 200 OK
{
    "task_id": "a1b2c3d4-...",
    "type": "recognize",
    "status": "processing",
    "progress": 45,
    "result": null
}
```

### Response (完成)
```
HTTP 200 OK
{
    "task_id": "a1b2c3d4-...",
    "type": "recognize",
    "status": "completed",
    "progress": 100,
    "result": {
        "title": "小星星",
        "artist": "",
        "page_count": 1,
        "musicxml_url": "/api/v1/files/a1b2c3d4/score.musicxml",
        "lrc_url": "/api/v1/files/a1b2c3d4/lyrics.lrc",
        "mp3_url": "/api/v1/files/a1b2c3d4/audio.mp3"
    }
}
```

### Response (失败)
```
HTTP 200 OK
{
    "task_id": "a1b2c3d4-...",
    "type": "recognize",
    "status": "failed",
    "progress": 30,
    "error": "无法识别图片中的乐谱，请确保图片清晰"
}
```

---

## POST /render

提交 MusicXML 内容，启动音频渲染。

### Request
```
POST /api/v1/render
Content-Type: application/json
{
    "musicxml": "<?xml version=\"1.0\"...",
    "soundfont": "default"   // 可选
}
```

### Response
```
HTTP 202 Accepted
{
    "task_id": "e5f6g7h8-...",
    "status": "pending"
}
```

---

## GET /files/{file_id}/{filename}

下载生成的文件。

### Request
```
GET /api/v1/files/a1b2c3d4/audio.mp3
```

### Response
```
HTTP 200 OK
Content-Type: audio/mpeg
<binary mp3 data>
```

### Error
```
HTTP 404 Not Found
{
    "detail": "文件不存在"
}
```
