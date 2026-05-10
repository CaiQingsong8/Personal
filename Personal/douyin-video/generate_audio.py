#!/usr/bin/env python3
"""用 FFmpeg 合成紧张感配乐，叠加到视频（简化版）"""

import subprocess, os

BASE = "/Users/apple/Aohua/douyin-video"
VIDEO = f"{BASE}/douyin_video_final.mp4"
OUT = f"{BASE}/output"

total = 34.25  # 总时长

# ── Step 1: 生成低频嗡鸣（紧张感底层）──
print("1/5 生成低频嗡鸣...")
subprocess.run([
    "ffmpeg", "-y",
    "-f", "lavfi", "-i", f"sine=frequency=55:duration={total}",
    "-af", "volume=0.12",
    "-c:a", "aac", "-b:a", "64k",
    f"{OUT}/drone.m4a"
], capture_output=True)
print(f"    drone: {os.path.getsize(f'{OUT}/drone.m4a')//1024}KB")

# ── Step 2: 生成心跳鼓点 ──
print("2/5 生成心跳鼓点...")
tick_cmd = "aevalsrc=exprs='0.35*sin(2*PI*90*t)*exp(-t*8)*(1 - abs(mod(t*1.3,1)-0.5)*2)^6':s=44100:n=75600"
subprocess.run([
    "ffmpeg", "-y",
    "-f", "lavfi", "-i", f"aevalsrc='0.4*sin(2*PI*85*t)*exp(-mod(t,0.75)*10)':s=44100:d={total}",
    "-af", "volume=0.25",
    "-c:a", "aac", "-b:a", "64k",
    f"{OUT}/beat.m4a"
], capture_output=True)
print(f"    beat: {os.path.getsize(f'{OUT}/beat.m4a')//1024}KB")

# ── Step 3: 关键节点重击 ──
print("3/5 生成情节重击音效...")
hit_points = [5, 10, 13, 20, 26]  # 香蕉震惊、芒果挑衅、草莓心虚、变身、复仇
hit_dur = [0.8, 0.5, 0.4, 1.2, 1.0]

for i, (t, d) in enumerate(zip(hit_points, hit_dur)):
    subprocess.run([
        "ffmpeg", "-y",
        "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
        "-f", "lavfi", "-i", f"sine=frequency=50:duration={d}",
        "-filter_complex",
        f"[0:a]atrim=0:{t}[sil];"
        f"[sil][1:a]concat=n=2:v=0:a=1,"
        f"afade=t=out:st={t+d-0.1}:d=0.1",
        "-c:a", "aac", "-b:a", "64k",
        f"{OUT}/hit{i}.m4a"
    ], capture_output=True)

# ── Step 4: 混音 ──
print("4/5 混音...")
mix_inputs = []
for f in ["drone.m4a"] + [f"hit{i}.m4a" for i in range(5)]:
    mix_inputs.extend(["-i", f"{OUT}/{f}"])

n = 6  # 1 drone + 5 hits
amix = f"[0:a]volume=0.8[a0];"
for i in range(1, n):
    amix += f"[{i}:a]volume=1.0[a{i}];"
amix += "".join(f"[a{i}]" for i in range(n)) + f"amix=inputs={n}:duration=longest:dropout_transition=0"

subprocess.run([
    "ffmpeg", "-y",
    *mix_inputs,
    "-filter_complex", amix,
    "-c:a", "aac", "-b:a", "128k",
    f"{OUT}/mixed.m4a"
], capture_output=True)
print(f"    mixed: {os.path.getsize(f'{OUT}/mixed.m4a')//1024}KB")

# ── Step 5: 合并音视频 ──
print("5/5 合并音视频...")
tmp = f"{BASE}/douyin_video_with_audio_tmp.mp4"
subprocess.run([
    "ffmpeg", "-y",
    "-i", VIDEO,
    "-i", f"{OUT}/mixed.m4a",
    "-c:v", "copy",
    "-c:a", "aac", "-b:a", "128k",
    "-shortest",
    tmp
], capture_output=True, check=True)

# Replace original
os.replace(tmp, VIDEO)

final = f"{BASE}/douyin_video_final.mp4"
size_mb = os.path.getsize(final) / 1024 / 1024
print(f"\n✅ 带声音的视频：{final}")
print(f"   大小: {size_mb:.1f} MB")
