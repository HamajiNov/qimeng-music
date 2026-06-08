"""文件下载接口"""

from pathlib import Path
from fastapi import APIRouter, HTTPException
from fastapi.responses import FileResponse
from app.config import settings

router = APIRouter()

CONTENT_TYPES = {
    ".musicxml": "application/vnd.recordare.musicxml+xml",
    ".xml": "application/xml",
    ".lrc": "text/plain; charset=utf-8",
    ".mp3": "audio/mpeg",
    ".mid": "audio/midi",
}


@router.get("/files/{file_id}/{filename}")
async def download_file(file_id: str, filename: str):
    """
    下载生成的文件。

    - file_id: 任务 ID（同时也是输出目录名）
    - filename: 文件名（如 audio.mp3, lyrics.lrc, score.musicxml）
    """
    file_path = settings.OUTPUT_DIR / file_id / filename

    if not file_path.exists():
        raise HTTPException(status_code=404, detail="文件不存在")

    if not file_path.is_file():
        raise HTTPException(status_code=404, detail="文件不存在")

    # 安全检查：防止路径穿越
    try:
        file_path.resolve().relative_to(settings.OUTPUT_DIR.resolve())
    except ValueError:
        raise HTTPException(status_code=403, detail="禁止访问")

    ext = Path(filename).suffix.lower()
    media_type = CONTENT_TYPES.get(ext, "application/octet-stream")

    return FileResponse(
        path=str(file_path),
        media_type=media_type,
        filename=filename,
    )
