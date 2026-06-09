"""
简谱训练数据生成器

流程:
    music21 随机生成旋律 → 导出 MusicXML → 渲染简谱图片 → 保存训练对

输出:
    output/images/     — 简谱图片 (PNG)
    output/musicxml/   — MusicXML 文件
    output/train.jsonl — Qwen2-VL 训练格式
"""

import os, random, json, base64
from pathlib import Path
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont

import music21
from music21 import (
    stream, note, meter, key, tempo, metadata,
    duration, interval, chord
)

OUTPUT_DIR = Path(__file__).parent / "output"
NUM_SAMPLES = 500  # 生成样本数

# 调号列表
KEYS = ["C", "G", "D", "F", "Bb", "A", "Eb", "E"]
# 拍号列表
TIME_SIGS = ["2/4", "3/4", "4/4", "6/8"]

# 简谱数字映射 (C大调)
PITCH_MAP = {0: "1", 2: "2", 4: "3", 5: "4", 7: "5", 9: "6", 11: "7"}


def generate_random_melody():
    """用 music21 生成一段随机旋律"""
    # 创建 Score → Part → Measures 结构
    s = stream.Score()

    # 随机调号、拍号
    k = key.Key(random.choice(KEYS))
    ts = meter.TimeSignature(random.choice(TIME_SIGS))
    mk = tempo.MetronomeMark(number=random.randint(60, 120))

    p = stream.Part()
    p.append(mk)
    p.append(k)
    p.append(ts)

    # 生成 8-16 个小节
    num_measures = random.randint(8, 16)
    beats_per_measure = int(ts.numerator) if ts.denominator == 4 else int(ts.numerator)

    # 为歌词随机选一些中文词
    lyrics_pool = [
        "一", "二", "三", "四", "五", "花", "草", "树", "木", "山", "水", "风",
        "云", "雨", "雪", "月", "日", "星", "天", "地", "光", "明", "红", "绿",
        "春", "夏", "秋", "冬", "鸟", "鱼", "梦", "路", "心", "爱", "美", "好",
        "思", "念", "飞", "舞", "歌", "笑", "泪", "阳", "河", "海", "蓝", "白",
    ]

    for m_i in range(num_measures):
        m = stream.Measure()
        # 每小节填充 beats_per_measure 拍
        remaining = beats_per_measure
        while remaining > 0:
            dur_choices = [0.5, 0.5, 1.0, 1.0, 1.0, 2.0]  # 偏向四分音符
            dur = random.choice(dur_choices)
            if dur > remaining:
                dur = remaining

            # 在 C 大调音阶内选音高 (避免离调太远)
            scale_degrees = [0, 2, 4, 5, 7, 9, 11]  # C大调音阶
            midi_offset = random.choice(scale_degrees) + 60  # 中央 C 附近

            n = note.Note()
            n.pitch.midi = midi_offset
            n.duration = duration.Duration(dur)

            # 随机加歌词
            if random.random() < 0.4:
                n.lyric = random.choice(lyrics_pool)

            m.append(n)
            remaining -= dur

        p.append(m)

    s.append(p)
    return s


def musicxml_to_jianpu_text(musicxml_path: str) -> str:
    """将 MusicXML 中的音符转换为简谱文本表示"""
    score = music21.converter.parse(musicxml_path)

    bpm = 100
    for el in score.flat.getElementsByClass(tempo.MetronomeMark):
        bpm = int(el.number)
        break

    lines = [f"BPM: {bpm}"]

    # 遍历每个声部、每个小节
    for part in score.parts:
        for m in part.getElementsByClass("Measure"):
            measure_notes = []
            for n in m.notesAndRests:
                if n.isRest:
                    measure_notes.append("0")
                else:
                    # 将 MIDI pitch 映射到简谱数字
                    midi = n.pitch.midi
                    degree = (midi - 60) % 12  # 相对 C 的度数
                    jp = PITCH_MAP.get(degree, "?")

                    # 八度标记
                    octave = (midi - 60) // 12
                    if octave >= 1:
                        jp = f"^{jp}"  # 高八度用 ^ 标记
                    elif octave <= -1:
                        jp = f".{jp}"  # 低八度用 . 标记

                    # 时值标记 (下划线)
                    dur_val = n.duration.quarterLength
                    if dur_val <= 0.25:
                        jp = f"={jp}="  # 十六分音符
                    elif dur_val <= 0.5:
                        jp = f"_{jp}"  # 八分音符
                    elif dur_val >= 3:
                        jp = f"{jp}--"  # 附点二分
                    elif dur_val >= 2:
                        jp = f"{jp}-"  # 二分

                    # 附点
                    if n.duration.dots > 0:
                        jp += "·"

                    # 歌词
                    if hasattr(n, 'lyric') and n.lyric:
                        jp += f"|{n.lyric}"

                    measure_notes.append(jp)

            lines.append(" ".join(measure_notes))

    return "\n".join(lines)


def render_jianpu_image(score: stream.Stream, title: str = "") -> Image.Image:
    """将 music21 Score 渲染为仿简谱图片"""
    width, height = 1400, 500
    img = Image.new("RGB", (width, height), "white")
    draw = ImageDraw.Draw(img)

    # 字体
    font_paths = [
        "/System/Library/Fonts/PingFang.ttc",
        "/System/Library/Fonts/STHeiti Light.ttc",
    ]
    f_title, f_num, f_lyric = None, None, None
    for fp in font_paths:
        try:
            f_title = ImageFont.truetype(fp, 32)
            f_num = ImageFont.truetype(fp, 24)
            f_lyric = ImageFont.truetype(fp, 16)
            break
        except (IOError, OSError):
            continue
    if f_num is None:
        f_title = f_num = f_lyric = ImageFont.load_default()

    # 解析 BPM 和 音符
    bpm = 100
    for el in score.flat.getElementsByClass(tempo.MetronomeMark):
        bpm = int(el.number)
        break

    ks = score.flat.getElementsByClass(key.Key)
    key_name = str(ks[0]) if ks else "C"

    # 标题行
    y = 10
    if title:
        draw.text((20, y), title, fill="black", font=f_title)
    y += 40
    draw.text((20, y), f"1={key_name}  {score.flat.getElementsByClass(meter.TimeSignature)[0] if score.flat.getElementsByClass(meter.TimeSignature) else '4/4'}  ♩={bpm}", fill="black", font=f_lyric)
    y += 35

    # 逐小节渲染
    x_start = 30
    x = x_start
    line_width = width - 60
    item_spacing = 10

    first_note_offset = 0
    for m in score.parts[0].getElementsByClass("Measure"):
        # 小节线
        draw.line([(x, y), (x, y + 55)], fill="black", width=1)

        notes_in_measure = list(m.notesAndRests)
        for n in notes_in_measure:
            if n.isRest:
                text = "0"
                octave_up = octave_down = False
            else:
                midi = n.pitch.midi
                degree = (midi - 60) % 12
                text = PITCH_MAP.get(degree, "?")
                octave = (midi - 60) // 12
                octave_up = octave >= 1
                octave_down = octave <= -1

            dur_val = float(n.duration.quarterLength)

            # 绘制音符数字
            note_y = y + 15
            if octave_up:
                draw.text((x, note_y - 10), "·", fill="black", font=f_num)  # 高八度点在上
            elif octave_down:
                draw.text((x, note_y + 15), "·", fill="black", font=f_num)  # 低八度点在下

            draw.text((x, note_y), text, fill="black", font=f_num)

            # 下划线 (减时线)
            if dur_val <= 0.5:
                lw = 2 if dur_val <= 0.25 else 1
                draw.line([(x - 2, note_y + 28), (x + 20, note_y + 28)], fill="black", width=lw)
                if dur_val <= 0.25:
                    draw.line([(x - 2, note_y + 33), (x + 20, note_y + 33)], fill="black", width=2)

            # 附点
            if n.duration.dots > 0:
                draw.text((x + 18, note_y + 5), "·", fill="black", font=f_num)

            # 歌词
            if hasattr(n, 'lyric') and n.lyric:
                draw.text((x - 2, y + 42), str(n.lyric), fill="black", font=f_lyric)

            x += 25 + item_spacing

            # 换行
            if x > x_start + line_width:
                x = x_start
                y += 70

        # 小节结束
        x += 5

    # 终线
    draw.line([(x, y), (x, y + 55)], fill="black", width=1)
    draw.line([(x + 2, y), (x + 2, y + 55)], fill="black", width=1)

    return img


def main():
    os.makedirs(OUTPUT_DIR / "images", exist_ok=True)
    os.makedirs(OUTPUT_DIR / "musicxml", exist_ok=True)

    train_data = []

    for i in range(NUM_SAMPLES):
        try:
            # 1. 生成随机旋律
            score = generate_random_melody()

            # 2. 导出 MusicXML
            xml_id = f"jp_{i:04d}"
            xml_path = OUTPUT_DIR / "musicxml" / f"{xml_id}.musicxml"
            score.write("musicxml", str(xml_path))

            # 3. 获取标题
            title = f"随机旋律 #{i+1}"

            # 4. 渲染简谱图片（直接用 music21 score）
            img = render_jianpu_image(score, title)
            img_path = OUTPUT_DIR / "images" / f"{xml_id}.png"
            img.save(str(img_path))

            # 6. 读取 MusicXML 内容
            xml_content = xml_path.read_text(encoding="utf-8")

            # 7. 构造训练样本
            img_b64 = base64.b64encode(
                open(img_path, "rb").read()
            ).decode()

            sample = {
                "id": xml_id,
                "image_path": str(img_path.relative_to(OUTPUT_DIR)),
                "musicxml_path": str(xml_path.relative_to(OUTPUT_DIR)),
                "title": title,
                # Qwen2-VL 训练格式
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"type": "image", "image": f"file://{img_path.absolute()}"},
                            {"type": "text", "text": "请识别这张简谱图片，输出完整的 MusicXML 乐谱文件。要求：\n1. 准确识别每个音符的数字(1-7)和音高\n2. 识别下划线对应的节奏(八分音符/十六分音符)\n3. 识别附点和延音线\n4. 识别歌词\n5. 输出标准 MusicXML 格式"}
                        ]
                    },
                    {
                        "role": "assistant",
                        "content": xml_content
                    }
                ]
            }
            train_data.append(sample)

            if (i + 1) % 50 == 0:
                print(f"[{i+1}/{NUM_SAMPLES}] 已生成...")

        except Exception as e:
            print(f"[{i}] 生成失败: {e}")
            continue

    # 8. 保存训练数据
    jsonl_path = OUTPUT_DIR / "train.jsonl"
    with open(jsonl_path, "w", encoding="utf-8") as f:
        for sample in train_data:
            f.write(json.dumps(sample, ensure_ascii=False) + "\n")

    print(f"\n完成! 共生成 {len(train_data)} 个训练样本")
    print(f"图片: {OUTPUT_DIR / 'images'}")
    print(f"MusicXML: {OUTPUT_DIR / 'musicxml'}")
    print(f"训练文件: {jsonl_path}")


if __name__ == "__main__":
    main()
