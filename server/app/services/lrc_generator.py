"""MusicXML → LRC 歌词文件生成器"""

from typing import List, Tuple
from pathlib import Path


def musicxml_to_lrc(musicxml_path: str) -> str:
    """
    从 MusicXML 文件生成 LRC 歌词文件。

    流程:
        1. 读取 MusicXML 中每个音符的 <lyric> 和 <duration>
        2. 根据 BPM 计算每个歌词行的时间戳
        3. 输出 LRC 格式文本

    Args:
        musicxml_path: MusicXML 文件路径

    Returns:
        LRC 格式的歌词文本
    """
    from music21 import converter, tempo

    score = converter.parse(musicxml_path)

    # 获取 BPM
    bpm = 120  # 默认
    for el in score.flat.getElementsByClass(tempo.MetronomeMark):
        bpm = el.number
        break

    # 获取标题和作者
    title = score.metadata.title or "未知"
    artist = score.metadata.composer or "未知"

    # 遍历所有声部，提取音符+歌词
    lyric_events: List[Tuple[float, str]] = []
    current_time = 0.0
    seconds_per_beat = 60.0 / bpm

    for part in score.parts:
        for measure in part.getElementsByClass("Measure"):
            for note in measure.notesAndRests:
                duration_beats = float(note.duration.quarterLength)
                duration_sec = duration_beats * seconds_per_beat

                # 检查是否有歌词
                if hasattr(note, 'lyric') and note.lyric:
                    text = note.lyric.strip()
                    if text:
                        lyric_events.append((current_time, text))

                current_time += duration_sec

    # 合并同一时间戳的歌词
    merged = _merge_lyric_events(lyric_events)

    # 生成 LRC
    lines = [
        f"[ti:{title}]",
        f"[ar:{artist}]",
        f"[length:{_format_time(current_time)}]",
        ""
    ]

    for timestamp, text in merged:
        lines.append(f"[{_format_time(timestamp)}]{text}")

    return "\n".join(lines)


def _merge_lyric_events(events: List[Tuple[float, str]]) -> List[Tuple[float, str]]:
    """合并时间戳相近的歌词事件"""
    if not events:
        return []

    merged = []
    current_time, current_text = events[0]

    for time, text in events[1:]:
        if abs(time - current_time) < 0.1:  # 100ms 以内视为同一行
            current_text += text
        else:
            merged.append((current_time, current_text))
            current_time, current_text = time, text

    merged.append((current_time, current_text))
    return merged


def _format_time(seconds: float) -> str:
    """格式化为 LRC 时间标签 [mm:ss.xx]"""
    minutes = int(seconds // 60)
    secs = seconds % 60
    return f"{minutes:02d}:{secs:05.2f}"
