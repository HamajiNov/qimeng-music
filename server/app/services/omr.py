"""Audiveris OMR 引擎封装"""

import glob
import os
import subprocess
import zipfile
import shutil
from pathlib import Path
from app.config import settings


class OMRException(Exception):
    """OMR 识别异常"""
    def __init__(self, message: str, detail: str = ""):
        self.message = message
        self.detail = detail
        super().__init__(message)


def run_audiveris(image_path: str, task_id: str) -> Path:
    """
    运行 Audiveris OMR 引擎。

    Args:
        image_path: 输入图片路径
        task_id: 任务 ID，用于输出目录

    Returns:
        生成的 .musicxml 文件路径

    Raises:
        OMRException: 识别失败
    """
    output_dir = settings.OUTPUT_DIR / task_id
    os.makedirs(output_dir, exist_ok=True)

    cmd = [
        settings.AUDIVERIS_BIN,
        "-batch",              # 批处理模式（无 GUI）
        "-export",             # 自动导出 MusicXML
        "-output", str(output_dir),
        image_path
    ]

    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=settings.AUDIVERIS_TIMEOUT
        )
    except subprocess.TimeoutExpired:
        raise OMRException("OMR 识别超时，图片可能太复杂或模糊")

    if result.returncode != 0:
        raise OMRException(
            "OMR 识别失败",
            detail=result.stderr[-500:]  # 最后 500 字符
        )

    # 查找生成的 .mxl 文件（压缩 MusicXML）
    mxl_files = glob.glob(f"{output_dir}/**/*.mxl", recursive=True)
    if not mxl_files:
        # 也尝试查找 .xml 文件
        xml_files = glob.glob(f"{output_dir}/**/*.xml", recursive=True)
        xml_files = [f for f in xml_files if "musicxml" not in f.lower() or "score" in f.lower()]
        if xml_files:
            xml_path = Path(xml_files[0])
            dest = output_dir / "score.musicxml"
            shutil.copy(xml_path, dest)
            return dest
        raise OMRException("未找到识别输出文件，请确保图片中包含五线谱")

    mxl_path = mxl_files[0]
    return _extract_mxl(mxl_path, output_dir / "score.musicxml")


def _extract_mxl(mxl_path: str, dest_path: Path) -> Path:
    """
    解压 .mxl 文件（实际是 ZIP 压缩包），提取根 MusicXML 文件。

    MXL 结构示例:
      myfile.mxl (ZIP)
        ├── META-INF/container.xml  ← 指向根 MusicXML
        └── score.xml               ← 实际的 MusicXML
    """
    temp_dir = Path(mxl_path).parent / "_mxl_extract"
    os.makedirs(temp_dir, exist_ok=True)

    with zipfile.ZipFile(mxl_path, 'r') as zf:
        zf.extractall(temp_dir)

    # 读取 container.xml 找到根 MusicXML
    container_path = temp_dir / "META-INF" / "container.xml"
    rootfile = "score.xml"  # 默认

    if container_path.exists():
        import xml.etree.ElementTree as ET
        tree = ET.parse(container_path)
        ns = {"c": "urn:oasis:names:tc:opendocument:xmlns:container"}
        rootfile_el = tree.find(".//c:rootfile", ns)
        if rootfile_el is not None:
            rootfile = rootfile_el.get("full-path", rootfile)

    score_xml = temp_dir / rootfile
    if not score_xml.exists():
        # 找一个 xml 文件
        xmls = list(temp_dir.glob("*.xml"))
        if xmls:
            score_xml = xmls[0]
        else:
            raise OMRException("无法解压 MXL 文件中的 MusicXML")

    shutil.copy(score_xml, dest_path)
    shutil.rmtree(temp_dir, ignore_errors=True)
    return dest_path


def preprocess_image(image_path: str) -> str:
    """
    图片预处理：灰度化、增强对比度、二值化。
    返回处理后的图片路径（可能为原图）。
    """
    try:
        from PIL import Image, ImageEnhance, ImageFilter

        img = Image.open(image_path).convert("L")  # 灰度化
        enhancer = ImageEnhance.Contrast(img)
        img = enhancer.enhance(1.5)                 # 增强对比度
        img = img.filter(ImageFilter.SHARPEN)       # 锐化

        # 二值化
        img = img.point(lambda x: 0 if x < 140 else 255)

        output_path = Path(image_path).parent / f"preprocessed_{Path(image_path).name}"
        img.save(output_path)
        return str(output_path)
    except ImportError:
        return image_path  # PIL 不可用时返回原图
