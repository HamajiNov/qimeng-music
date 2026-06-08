"""Celery 应用配置"""

from celery import Celery
from app.config import settings

celery_app = Celery(
    "qimeng_music",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
)

celery_app.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="Asia/Shanghai",
    enable_utc=True,
    task_track_started=True,
    task_soft_time_limit=settings.TASK_TIMEOUT,
    task_time_limit=settings.TASK_TIMEOUT + 60,
)

celery_app.autodiscover_tasks(["app.workers.tasks"])
