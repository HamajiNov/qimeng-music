"""MusicXML → MP3 音频渲染"""

import os
import subprocess
from pathlib import Path
from app.config import settings


class AudioException(Exception):
    """音频渲染异常"""
    def __init__(self, message: str, detail: str = ""):
        self.message = message
        self.detail = detail
        super().__init__(message)


def musicxml_to_mp3(musicxml_path: str, output_dir: Path) -> Path:
    """
    MusicXML → MIDI → WAV → MP3 渲染管道。

    Args:
        musicxml_path: MusicXML 文件路径
        output_dir: 输出目录

    Returns:
        生成的 MP3 文件路径
    """
    os.makedirs(output_dir, exist_ok=True)

    midi_path = output_dir / "score.mid"
    wav_path = output_dir / "score.wav"
    mp3_path = output_dir / "audio.mp3"

    # Step 1: MusicXML → MIDI (music21)
    _musicxml_to_midi(musicxml_path, midi_path)

    # Step 2: MIDI → WAV (FluidSynth)
    _midi_to_wav(midi_path, wav_path)

    # Step 3: WAV → MP3 (ffmpeg)
    _wav_to_mp3(wav_path, mp3_path)

    # 清理中间文件
    midi_path.unlink(missing_ok=True)
    wav_path.unlink(missing_ok=True)

    return mp3_path


def _musicxml_to_midi(musicxml_path: str, midi_path: Path):
    """使用 music21 将 MusicXML 转 MIDI"""
    from music21 import converter
    score = converter.parse(musicxml_path)
    score.write("midi", str(midi_path))


def _midi_to_wav(midi_path: Path, wav_path: Path):
    """使用 FluidSynth 将 MIDI 渲染为 WAV"""
    sf_path = settings.DEFAULT_SOUNDFONT

    if not sf_path.exists():
        raise AudioException(
            "SoundFont 文件未找到，请将 .sf2 文件放入 data/soundfonts/ 目录",
            detail=f"期望路径: {sf_path}"
        )

    cmd = [
        "fluidsynth",
        "-ni",                    # 无交互模式
        "-g", "2.0",              # 增益
        "-F", str(wav_path),      # 输出 WAV
        str(sf_path),
        str(midi_path)
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)

    if result.returncode != 0 or not wav_path.exists():
        raise AudioException("音频合成失败", detail=result.stderr[-500:])


def _wav_to_mp3(wav_path: Path, mp3_path: Path):
    """使用 ffmpeg 将 WAV 转 MP3"""
    cmd = [
        "ffmpeg",
        "-y",                     # 覆盖已有文件
        "-i", str(wav_path),
        "-b:a", "320k",           # 320kbps 高质量
        "-loglevel", "error",     # 只输出错误
        str(mp3_path)
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)

    if result.returncode != 0 or not mp3_path.exists():
        raise AudioException("MP3 转码失败", detail=result.stderr[-500:])
