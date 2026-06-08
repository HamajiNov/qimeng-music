# 启蒙乐谱 (Qimeng Music)

## 项目概要
- 类型：iOS App + Python 后端
- 技术栈：SwiftUI(iOS 18+) / WKWebView(alphaTab) / Python FastAPI / Celery / Audiveris
- 职责边界：
  - iOS：乐谱拍照上传、乐谱渲染展示、KTV 歌词同步播放
  - 后端：OMR 识别、MusicXML→MP3 渲染、LRC 歌词生成

## 架构与模块

### iOS 端
- 页面结构：
  - Tab 1: ScoreLibraryView（乐谱库列表）
  - Tab 2: ScanView（拍照/相册选图 → 上传识别）
  - Tab 3: ProfileView（设置/存储管理）
  - ScoreDetailView（全屏：乐谱展示 + 播放控制 + 歌词）
- 核心模块：
  - alphaTab WKWebView（乐谱渲染）
  - KTVLyricsPlayer（AVPlayer + LRC 同步）
  - NetworkLayer（URLSession + async/await）
  - LocalCacheManager（FileManager 文件管理）

### 服务端
- 分层：Router → Service → Worker
- 包结构：
  - app/api/v1/ — recognize.py / render.py / files.py
  - app/services/ — omr.py / lrc_generator.py / audio.py
  - app/workers/ — celery_app.py / tasks.py
  - app/models/ — task.py
  - app/schemas/ — task.py
- 外部依赖：Audiveris (Java), music21, FluidSynth, Redis

## 接口文档
> 详见 [docs/api.md](./docs/api.md)

## 交互文档
> 详见 [docs/interaction.md](./docs/interaction.md)

## 版本历史
| 版本 | 简要 | 状态 | 文档 |
|------|------|------|------|
| v1.0.0 | MVP：拍照识别 + 乐谱展示 + KTV 播放 | 🔧 开发中 | [v1.0.0.md](./docs/versions/v1.0.0.md) |
