#!/usr/bin/env python3
"""合成抖音AI短剧视频 — 水果圈·背叛 (字幕图叠加方案)"""

import subprocess, os, sys
from PIL import Image, ImageDraw, ImageFont

BASE = "/Users/apple/Aohua/douyin-video"
IMG_DIR = f"{BASE}/images"
OUT = f"{BASE}/output"
os.makedirs(OUT, exist_ok=True)

scenes = [
    ("scene1.png", 5, "我以为我们之间，是甜的。"),
    ("scene2.png", 5, "但你和她，在看不见的地方……"),
    ("scene3.png", 3, "原来我只是，一根被选中的香蕉。"),
    ("scene4.png", 4, "芒果说：兄弟，她喜欢热带风情。"),
    ("scene5.png", 3, "她甚至不敢看我的眼睛。"),
    ("scene6.png", 6, "但我不会永远软下去！"),
    ("scene7.png", 5, "每一根香蕉，都有变黑的那一天。"),
    ("scene8.png", 5, "真正甜的……是独自强大 🍌👑"),
]

# ── Step 0: Generate subtitle PNG images ──
print("Generating subtitle images...")
for idx, (_, _, subtitle) in enumerate(scenes, 1):
    img = Image.new("RGBA", (1080, 200), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 44)
    except:
        font = ImageFont.truetype("/System/Library/Fonts/STHeiti Light.ttc", 44)

    bbox = draw.textbbox((0, 0), subtitle, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (1080 - tw) // 2
    y = (200 - th) // 2

    # Shadow
    draw.text((x+2, y+2), subtitle, font=font, fill=(0, 0, 0, 180))
    # White text
    draw.text((x, y), subtitle, font=font, fill=(255, 255, 255, 255))

    sub_path = f"{OUT}/sub_{idx:02d}.png"
    img.save(sub_path)
    print(f"  Sub {idx}: {subtitle}")

scenes_config = scenes  # keep for reference

# ── Step 1: Create individual video clips with zoom + subtitle overlay ──
print("\nRendering video clips...")
segments = []
for idx, (img_file, duration, subtitle) in enumerate(scenes, 1):
    seg_path = f"{OUT}/seg_{idx:02d}.mp4"
    segments.append(seg_path)
    sub_path = f"{OUT}/sub_{idx:02d}.png"

    zoom = (
        f"zoompan=z='min(zoom+0.0020,1.08)':d=1:"
        f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
        f"fps=30:s=1080x1920"
    )

    cmd = [
        "ffmpeg", "-y",
        "-i", f"{IMG_DIR}/{img_file}",
        "-i", sub_path,
        "-filter_complex",
        f"[0:v]{zoom}[v0];"
        f"[1:v]loop=-1:1:0,setpts=N/30/TB[sub];"
        f"[v0][sub]overlay=x=(W-w)/2:y=H-h-100",
        "-c:v", "libx264",
        "-preset", "fast",
        "-crf", "18",
        "-pix_fmt", "yuv420p",
        "-t", str(duration),
        seg_path
    ]

    print(f"  [{idx}/8] {duration}s...", end=" ", flush=True)
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        err = r.stderr
        print(f"ERROR")
        # print last relevant lines
        for line in err.split("\n")[-5:]:
            print(f"    {line}")
        sys.exit(1)
    print(f"OK ({os.path.getsize(seg_path)//1024}KB)")

# ── Step 2: Concat with xfade ──
print("\nConcatenating with crossfade...")

inputs = []
for s in segments:
    inputs.extend(["-i", s])

filters = []
prev = "0:v"
for i in range(1, len(segments)):
    label = f"t{i}"
    # offset: cumulative duration of all previous inputs minus all previous fade overlaps
    offset = sum(s[1] for s in scenes[:i]) - (i * 0.25)
    filters.append(f"[{prev}][{i}:v]xfade=transition=fade:duration=0.25:offset={offset}[{label}]")
    prev = label

concat_cmd = [
    "ffmpeg", "-y",
    *inputs,
    "-filter_complex", ";".join(filters),
    "-map", f"[{prev}]",
    "-c:v", "libx264",
    "-preset", "fast",
    "-crf", "18",
    "-pix_fmt", "yuv420p",
    f"{BASE}/douyin_video_final.mp4"
]

r = subprocess.run(concat_cmd, capture_output=True, text=True)
if r.returncode != 0:
    print("Concat failed:")
    for line in r.stderr.split("\n")[-6:]:
        print(f"  {line}")
    sys.exit(1)

final = f"{BASE}/douyin_video_final.mp4"
size_mb = os.path.getsize(final) / 1024 / 1024
total = sum(s[1] for s in scenes) - 0.25 * (len(scenes) - 1)
print(f"\n{'='*50}")
print(f"✅ 视频生成完毕！")
print(f"   文件: {final}")
print(f"   大小: {size_mb:.1f} MB")
print(f"   时长: ~{total:.0f} 秒")
print(f"   格式: 1080x1920 MP4 (9:16 竖屏)")
