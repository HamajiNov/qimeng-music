"""乐谱识别接口"""

import os
import uuid
import aiofiles
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.config import settings
from app.schemas.task import RecognizeResponse
from app.models.task import Task, TaskType, TaskStatus, Base
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

router = APIRouter()

ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif"}


def _get_session():
    engine = create_engine("sqlite:///" + str(settings.DATA_DIR / "tasks.db"))
    Base.metadata.create_all(engine)
    return sessionmaker(bind=engine)()


@router.post("/recognize", response_model=RecognizeResponse, status_code=202)
async def recognize_score(image: UploadFile = File(...)):
    """
    上传乐谱图片，启动异步 OMR 识别任务。

    - 支持格式: JPG, PNG, BMP, TIFF
    - 最大大小: 10MB
    """
    # 验证文件类型
    ext = os.path.splitext(image.filename or "")[1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(
            status_code=400,
            detail=f"不支持的文件格式: {ext}。支持: {', '.join(ALLOWED_EXTENSIONS)}"
        )

    # 验证文件大小（读取内容）
    contents = await image.read()
    if len(contents) > settings.MAX_UPLOAD_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"文件过大，最大支持 {settings.MAX_UPLOAD_SIZE // (1024*1024)}MB"
        )

    # 创建任务
    task_id = str(uuid.uuid4())
    input_dir = settings.INPUT_DIR / task_id
    os.makedirs(input_dir, exist_ok=True)

    # 保存图片
    filename = f"input{ext}"
    image_path = input_dir / filename
    async with aiofiles.open(image_path, "wb") as f:
        await f.write(contents)

    # 保存任务记录
    session = _get_session()
    task = Task(id=task_id, type=TaskType.RECOGNIZE, status=TaskStatus.PENDING)
    session.add(task)
    session.commit()
    session.close()

    # 提交 Celery 任务
    from app.workers.tasks import process_omr
    process_omr.delay(task_id, filename)

    return RecognizeResponse(task_id=task_id)
