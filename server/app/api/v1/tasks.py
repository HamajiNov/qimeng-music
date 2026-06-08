"""任务状态查询接口"""

from fastapi import APIRouter, HTTPException
from app.config import settings
from app.schemas.task import TaskResponse, TaskResult
from app.models.task import Task, TaskStatus, Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

router = APIRouter()


def _get_session():
    engine = create_engine("sqlite:///" + str(settings.DATA_DIR / "tasks.db"))
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


@router.get("/tasks/{task_id}", response_model=TaskResponse)
async def get_task(task_id: str):
    """查询识别/渲染任务的状态"""
    session = _get_session()
    task = session.query(Task).filter_by(id=task_id).first()
    session.close()

    if not task:
        raise HTTPException(status_code=404, detail="任务不存在")

    result = None
    if task.status == TaskStatus.COMPLETED:
        result = TaskResult(
            title=task.result_title,
            artist=task.result_artist,
            page_count=task.result_page_count,
            musicxml_url=f"/api/v1/files/{task_id}/score.musicxml",
            lrc_url=f"/api/v1/files/{task_id}/lyrics.lrc",
            mp3_url=f"/api/v1/files/{task_id}/audio.mp3",
        )

    return TaskResponse(
        task_id=task.id,
        type=task.type.value if task.type else "",
        status=task.status.value if task.status else "pending",
        progress=task.progress or 0,
        result=result,
        error=task.error,
        created_at=task.created_at,
    )
