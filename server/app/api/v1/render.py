"""MusicXML 渲染接口"""

import uuid
from fastapi import APIRouter
from app.config import settings
from app.schemas.task import RecognizeResponse, RenderRequest
from app.models.task import Task, TaskType, TaskStatus, Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

router = APIRouter()


def _get_session():
    engine = create_engine("sqlite:///" + str(settings.DATA_DIR / "tasks.db"))
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


@router.post("/render", response_model=RecognizeResponse, status_code=202)
async def render_score(request: RenderRequest):
    """
    提交 MusicXML 内容，启动异步音频渲染。

    返回 task_id，通过 GET /tasks/{task_id} 轮询结果。
    """
    # 基础校验：检查是否为有效 XML
    if not request.musicxml.strip().startswith("<?xml") and not request.musicxml.strip().startswith("<"):
        return RecognizeResponse(task_id="", status="pending")
        # 实际会由 Celery 任务中 music21 解析时抛出异常

    task_id = str(uuid.uuid4())

    session = _get_session()
    task = Task(id=task_id, type=TaskType.RENDER, status=TaskStatus.PENDING)
    session.add(task)
    session.commit()
    session.close()

    from app.workers.tasks import process_render
    process_render.delay(task_id, request.musicxml)

    return RecognizeResponse(task_id=task_id)
