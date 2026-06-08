"""应用配置"""

import os
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

class Settings:
    APP_NAME: str = "启蒙乐谱 API"
    VERSION: str = "1.0.0"
    DEBUG: bool = os.getenv("DEBUG", "false").lower() == "true"

    # Redis
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")

    # Celery
    CELERY_BROKER_URL: str = REDIS_URL
    CELERY_RESULT_BACKEND: str = REDIS_URL

    # File Storage
    INPUT_DIR: Path = DATA_DIR / "input"
    OUTPUT_DIR: Path = DATA_DIR / "output"
    SOUNDFONT_DIR: Path = DATA_DIR / "soundfonts"
    DEFAULT_SOUNDFONT: Path = SOUNDFONT_DIR / "default.sf2"

    # OMR
    AUDIVERIS_BIN: str = os.getenv(
        "AUDIVERIS_BIN",
        "/Applications/Audiveris.app/Contents/MacOS/Audiveris"
    )
    AUDIVERIS_TIMEOUT: int = 300  # 秒
    TASK_TIMEOUT: int = 600       # 秒

    # Upload
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB

settings = Settings()
