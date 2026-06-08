"""Pydantic 数据模型"""

from typing import Optional
from datetime import datetime
from pydantic import BaseModel, Field


class RecognizeResponse(BaseModel):
    task_id: str
    status: str = "pending"


class RenderRequest(BaseModel):
    musicxml: str = Field(..., description="完整的 MusicXML XML 文本")
    soundfont: str = Field("default", description="SoundFont 名称")


class TaskResult(BaseModel):
    title: Optional[str] = None
    artist: Optional[str] = None
    page_count: Optional[int] = None
    musicxml_url: Optional[str] = None
    lrc_url: Optional[str] = None
    mp3_url: Optional[str] = None


class TaskResponse(BaseModel):
    task_id: str
    type: str
    status: str
    progress: int = 0
    result: Optional[TaskResult] = None
    error: Optional[str] = None
    created_at: Optional[datetime] = None


class HealthResponse(BaseModel):
    status: str = "ok"
    version: str
