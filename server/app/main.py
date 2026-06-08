"""
启蒙乐谱 API — FastAPI 入口

启动:
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
"""

import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

app = FastAPI(
    title=settings.APP_NAME,
    version=settings.VERSION,
    description="乐谱 OMR 识别与音频渲染服务",
)

# CORS — 允许 iOS 客户端访问
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # MVP 阶段全开放
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
from app.api.v1.recognize import router as recognize_router
from app.api.v1.tasks import router as tasks_router
from app.api.v1.render import router as render_router
from app.api.v1.files import router as files_router

app.include_router(recognize_router, prefix="/api/v1", tags=["Recognize"])
app.include_router(tasks_router, prefix="/api/v1", tags=["Tasks"])
app.include_router(render_router, prefix="/api/v1", tags=["Render"])
app.include_router(files_router, prefix="/api/v1", tags=["Files"])


@app.get("/health", tags=["Health"])
async def health_check():
    """健康检查"""
    return {"status": "ok", "version": settings.VERSION}


@app.on_event("startup")
async def startup():
    """启动时创建必要目录"""
    os.makedirs(settings.INPUT_DIR, exist_ok=True)
    os.makedirs(settings.OUTPUT_DIR, exist_ok=True)
    os.makedirs(settings.SOUNDFONT_DIR, exist_ok=True)
