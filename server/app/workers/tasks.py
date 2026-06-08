"""Celery 异步任务"""

import os
import uuid
from pathlib import Path

from app.config import settings
from app.workers.celery_app import celery_app


@celery_app.task(bind=True, name="process_omr")
def process_omr(self, task_id: str, image_filename: str):
    """
    异步 OMR 识别任务。

    流程:
        1. 图片预处理
        2. Audiveris OMR 识别
        3. 生成 LRC 歌词
        4. 渲染 MP3 音频

    Args:
        task_id: 任务 ID
        image_filename: 上传的图片文件名
    """
    from app.models.task import Task, TaskStatus
    from app.models.task import Base as ModelBase
    from app.services.omr import run_audiveris, preprocess_image, OMRException
    from app.services.lrc_generator import musicxml_to_lrc
    from app.services.audio import musicxml_to_mp3, AudioException

    # 使用 SQLite 作为任务状态存储（简单）
    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker

    engine = create_engine("sqlite:///" + str(settings.DATA_DIR / "tasks.db"))
    ModelBase.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)

    def update_task(status: TaskStatus, progress: int, **kwargs):
        session = Session()
        task = session.query(Task).filter_by(id=task_id).first()
        if task:
            task.status = status
            task.progress = progress
            for key, value in kwargs.items():
                setattr(task, key, value)
            session.commit()
        session.close()

    try:
        # Step 1: 读取图片
        update_task(TaskStatus.PROCESSING, 5)
        image_path = settings.INPUT_DIR / task_id / image_filename

        if not image_path.exists():
            update_task(TaskStatus.FAILED, 0, error="上传图片未找到")
            return

        # Step 2: 图片预处理
        update_task(TaskStatus.PROCESSING, 10)
        processed_path = preprocess_image(str(image_path))

        # Step 3: OMR 识别
        update_task(TaskStatus.PROCESSING, 20)
        musicxml_path = run_audiveris(processed_path, task_id)

        # Step 4: 生成 LRC
        update_task(TaskStatus.PROCESSING, 60)
        lrc_content = musicxml_to_lrc(str(musicxml_path))
        lrc_path = settings.OUTPUT_DIR / task_id / "lyrics.lrc"
        lrc_path.write_text(lrc_content, encoding="utf-8")

        # Step 5: 渲染 MP3
        update_task(TaskStatus.PROCESSING, 75)
        mp3_path = musicxml_to_mp3(str(musicxml_path), settings.OUTPUT_DIR / task_id)

        # Step 6: 提取元数据
        update_task(TaskStatus.PROCESSING, 95)
        title, artist = _extract_metadata(musicxml_path)
        page_count = _count_pages(musicxml_path)

        # 完成
        update_task(
            TaskStatus.COMPLETED, 100,
            result_title=title,
            result_artist=artist,
            result_page_count=page_count,
        )

    except OMRException as e:
        update_task(TaskStatus.FAILED, 0, error=e.message)
    except AudioException as e:
        update_task(TaskStatus.FAILED, 80, error=e.message)
    except Exception as e:
        update_task(TaskStatus.FAILED, 0, error=f"未知错误: {str(e)}")


@celery_app.task(bind=True, name="process_render")
def process_render(self, task_id: str, musicxml_content: str):
    """
    异步音频渲染任务：接收 MusicXML 文本，生成 MP3。

    Args:
        task_id: 任务 ID
        musicxml_content: MusicXML 完整 XML 文本
    """
    from app.models.task import Task, TaskStatus
    from app.models.task import Base as ModelBase
    from app.services.audio import musicxml_to_mp3, AudioException

    from sqlalchemy import create_engine
    from sqlalchemy.orm import sessionmaker

    engine = create_engine("sqlite:///" + str(settings.DATA_DIR / "tasks.db"))
    ModelBase.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)

    def update_task(status: TaskStatus, progress: int, **kwargs):
        session = Session()
        task = session.query(Task).filter_by(id=task_id).first()
        if task:
            task.status = status
            task.progress = progress
            for key, value in kwargs.items():
                setattr(task, key, value)
            session.commit()
        session.close()

    try:
        update_task(TaskStatus.PROCESSING, 10)

        # 写入 MusicXML 文件
        output_dir = settings.OUTPUT_DIR / task_id
        os.makedirs(output_dir, exist_ok=True)
        musicxml_path = output_dir / "score.musicxml"
        musicxml_path.write_text(musicxml_content, encoding="utf-8")

        update_task(TaskStatus.PROCESSING, 30)

        # 渲染 MP3
        mp3_path = musicxml_to_mp3(str(musicxml_path), output_dir)

        update_task(TaskStatus.COMPLETED, 100)

    except AudioException as e:
        update_task(TaskStatus.FAILED, 0, error=e.message)
    except Exception as e:
        update_task(TaskStatus.FAILED, 0, error=f"未知错误: {str(e)}")


def _extract_metadata(musicxml_path: Path) -> tuple:
    """从 MusicXML 提取标题和作者"""
    try:
        from music21 import converter
        score = converter.parse(str(musicxml_path))
        title = score.metadata.title or ""
        artist = score.metadata.composer or ""
        return title, artist
    except Exception:
        return "", ""


def _count_pages(musicxml_path: Path) -> int:
    """统计 MusicXML 页数"""
    try:
        import xml.etree.ElementTree as ET
        tree = ET.parse(musicxml_path)
        pages = tree.findall(".//{*}page-number")
        return len(set(p.text for p in pages)) if pages else 1
    except Exception:
        return 1
