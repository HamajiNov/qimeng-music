"""任务模型"""

import enum
import uuid
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, Text, Enum
from sqlalchemy.orm import declarative_base

Base = declarative_base()


class TaskType(str, enum.Enum):
    RECOGNIZE = "recognize"
    RENDER = "render"


class TaskStatus(str, enum.Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"


class Task(Base):
    __tablename__ = "tasks"

    id = Column(String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    type = Column(Enum(TaskType), nullable=False)
    status = Column(Enum(TaskStatus), default=TaskStatus.PENDING, nullable=False)
    progress = Column(Integer, default=0)
    error = Column(Text, nullable=True)
    result_title = Column(String(255), nullable=True)
    result_artist = Column(String(255), nullable=True)
    result_page_count = Column(Integer, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    @property
    def output_path(self):
        from app.config import settings
        return settings.OUTPUT_DIR / self.id
