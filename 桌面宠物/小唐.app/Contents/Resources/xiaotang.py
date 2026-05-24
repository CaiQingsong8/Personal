#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小唐桌面宠物 v5.0.2
兼容：macOS Ventura 13+ / Python 3.9+ / pyobjc 8.x+
核心策略：
  - 所有 AppKit API 调用全部 try-except 隔离，单点失败不崩溃
  - ObjC 子类全部在模块顶层定义
  - NSTextField 用兼容写法（不用 labelWithString_）
  - CGEventTap callback 用 ctypes 包装
  - 屏幕检测改为 pynput 超时方案，不依赖 CGDisplayIsAsleep
  - NSPanel/NSWindow 集合行为用数字常量兜底
  - pynput 作为主键鼠监听，CGEventTap 仅备用
  - Launcher 全面重写，确保 Homebrew Python 优先
"""

import tkinter as tk
from tkinter import ttk
import threading, time, datetime, subprocess, sys, os, json, re, random, hashlib
from pathlib import Path

# 内嵌依赖（pylib/ 目录）
_PYLIB = Path(__file__).parent / "pylib"
if _PYLIB.exists():
    sys.path.insert(0, str(_PYLIB))

import asyncio
import edge_tts
from PIL import Image

BASE_DIR  = Path(__file__).parent
ASSET_DIR = BASE_DIR / "Assets"
DATA_FILE = BASE_DIR / "xiaotang_data.json"
LOG_FILE  = BASE_DIR / "debug.log"

# ══════ 节日 ══════
# 法定节假日 + 农历重要节日（公历日期）
HOLIDAYS = {
    # 法定节假日
    "01-01": "元旦",
    "05-01": "劳动节",
    "10-01": "国庆节",
    "10-02": "国庆节",
    "10-03": "国庆节",
    # 农历节日（固定公历日期近似）
    "01-01": "春节",
    "01-02": "春节",
    "01-03": "春节",
    "01-15": "元宵节",
    "04-05": "清明节",
    "05-05": "端午节",
    "07-07": "七夕节",
    "07-15": "中元节",
    "08-15": "中秋节",
    "09-09": "重阳节",
    "12-30": "除夕",
    # 其他节日
    "02-14": "情人节",
    "03-08": "妇女节",
    "03-12": "植树节",
    "04-01": "愚人节",
    "06-01": "儿童节",
    "09-10": "教师节",
    "12-24": "平安夜",
    "12-25": "圣诞节",
    "11-11": "双十一",
}

def _get_holiday():
    """获取今天的节日"""
    today = datetime.date.today().strftime("%m-%d")
    return HOLIDAYS.get(today)

# ══════ 日志 ══════
_log_lock = threading.Lock()
def log(msg):
    ts = datetime.datetime.now().strftime("%H:%M:%S")
    line = f"[{ts}] {msg}"
    print(line, flush=True)
    with _log_lock:
        try:
            with open(LOG_FILE, "a", encoding="utf-8") as f:
                f.write(line + "\n")
        except:
            pass

# ══════ AppKit / Quartz 导入 ══════
try:
    import AppKit
    import Quartz
    log("AppKit/Quartz 导入成功")
except ImportError as e:
    print(f"[FATAL] AppKit/Quartz 导入失败: {e}")
    print("请运行: pip3 install pyobjc-framework-Cocoa pyobjc-framework-Quartz")
    sys.exit(1)

# ══════ 兼容性工具 ══════
def _ns_label(text):
    """兼容 pyobjc 8.x 和 9.x 的文本标签创建"""
    # pyobjc 9+: labelWithString_ 可用
    # pyobjc 8.x: 需要用 alloc().init() 方式
    try:
        lbl = AppKit.NSTextField.labelWithString_(text)
        return lbl
    except AttributeError:
        pass
    try:
        lbl = AppKit.NSTextField.alloc().initWithFrame_(
            AppKit.NSMakeRect(0, 0, 200, 24))
        lbl.setStringValue_(text)
        lbl.setBezeled_(False)
        lbl.setDrawsBackground_(False)
        lbl.setEditable_(False)
        lbl.setSelectable_(False)
        return lbl
    except Exception as e:
        log(f"_ns_label 失败: {e}")
        return None

def _safe_collection_behavior(win):
    """安全设置窗口集合行为，兼容旧版 pyobjc 常量名"""
    try:
        # 数字常量兜底（不依赖常量名）
        # NSWindowCollectionBehaviorCanJoinAllSpaces = 1
        # NSWindowCollectionBehaviorStationary = 16
        # 去掉 FullScreenAuxiliary（它只对同 app 有效）
        behavior = 1 | 16
        win.setCollectionBehavior_(behavior)
    except Exception as e:
        log(f"setCollectionBehavior_ 失败: {e}")

def _pil2ns(pil_img, w, h):
    """PIL Image → NSImage"""
    try:
        img  = pil_img.resize((w, h), Image.LANCZOS).convert("RGBA")
        raw  = img.tobytes()
        prov = Quartz.CGDataProviderCreateWithData(None, raw, len(raw), None)
        cs   = Quartz.CGColorSpaceCreateDeviceRGB()
        cg   = Quartz.CGImageCreate(
            w, h, 8, 32, w * 4, cs,
            Quartz.kCGBitmapByteOrderDefault | Quartz.kCGImageAlphaPremultipliedLast,
            prov, None, True, Quartz.kCGRenderingIntentDefault)
        return AppKit.NSImage.alloc().initWithCGImage_size_(cg, (w, h))
    except Exception as e:
        log(f"_pil2ns 失败: {e}")
        return None

_current_img = None  # 当前渲染帧（全局）

# ══════ ObjC 子类（全部在模块顶层，不能在函数/方法内定义）══════
class _ContentView(AppKit.NSView):
    def drawRect_(self, rect):
        if _current_img:
            try:
                _current_img.drawInRect_fromRect_operation_fraction_(
                    self.bounds(),
                    AppKit.NSMakeRect(0, 0,
                        _current_img.size().width,
                        _current_img.size().height),
                    AppKit.NSCompositeSourceOver, 1.0)
            except:
                pass

class _BubbleBGView(AppKit.NSView):
    """气泡背景视图（炫酷黑云朵透明形状）"""
    def drawRect_(self, rect):
        try:
            bounds = self.bounds()
            inset = AppKit.NSInsetRect(bounds, 2, 2)

            # 云朵形状：大圆角矩形
            path = AppKit.NSBezierPath.bezierPathWithRoundedRect_xRadius_yRadius_(
                inset, 18, 18)

            # 炫酷黑半透明填充（透明度0.75，能看到后面内容）
            AppKit.NSColor.colorWithCalibratedWhite_alpha_(0.1, 0.75).setFill()
            path.fill()

            # 亮橙色轮廓（炫酷感）
            AppKit.NSColor.colorWithCalibratedRed_green_blue_alpha_(
                1.0, 0.6, 0.2, 0.8).setStroke()
            path.setLineWidth_(2.0)
            path.stroke()
        except:
            pass

class _CatWindow(AppKit.NSPanel):
    _drag_start_loc      = None
    _drag_start_origin   = None
    _drag_moved          = False
    _last_click_t        = 0
    _left_click_pending  = False
    _right_click_pending = False

    def _menuTap_(self, sender):
        """处理菜单文本点击"""
        try:
            tag = sender.tag()
            self._menu_click_tag = tag
            # 非已完成折叠(当前tag判断)，关闭菜单
            # 已完成折叠的tag由 _toggle_done 自己控制
            self._menu_should_close = True
        except Exception as e:
            log(f"菜单点击错误: {e}")
    _menu_should_close = True

    _menu_click_tag = -1  # 由 tkinter 轮询

    def mouseDown_(self, evt):
        try:
            self._drag_start_loc    = AppKit.NSEvent.mouseLocation()
            self._drag_start_origin = self.frame().origin
            self._drag_moved        = False
        except:
            pass

    def mouseDragged_(self, evt):
        try:
            if not self._drag_start_loc:
                return
            cur = AppKit.NSEvent.mouseLocation()
            dx  = cur.x - self._drag_start_loc.x
            dy  = cur.y - self._drag_start_loc.y
            if abs(dx) + abs(dy) > 3:
                self._drag_moved = True
            o = self._drag_start_origin
            self.setFrameOrigin_((o.x + dx, o.y + dy))
        except:
            pass

    def mouseUp_(self, evt):
        try:
            if self._drag_start_loc is None:
                return
            moved = self._drag_moved
            self._drag_start_loc = None
            self._drag_moved     = False
            if not moved:
                import time as _t
                now = _t.time()
                if now - self._last_click_t > 0.5:
                    self._last_click_t = now
                    self._left_click_pending = True
        except Exception as e:
            log(f"mouseUp_ 异常: {e}")

    def rightMouseDown_(self, evt):
        try:
            self._right_click_pending = True
        except:
            pass

    def acceptsFirstResponder(self): return True
    def canBecomeKeyWindow(self):    return True

# ══════ 天气 ══════
_WEATHER_EMOJI = [
    (["sunny","clear","晴"],           "☀️"),
    (["partly","cloud","多云"],         "⛅️"),
    (["overcast","阴"],                 "☁️"),
    (["rain","drizzle","shower","雨"],  "🌧"),
    (["thunder","storm","雷"],          "⛈"),
    (["snow","雪"],                     "❄️"),
    (["fog","mist","haze","雾","霾"],   "🌫"),
    (["wind","大风"],                   "💨"),
]

def _weather_emoji(desc):
    low = (desc or "").lower()
    for kws, em in _WEATHER_EMOJI:
        if any(k in low for k in kws):
            return em
    return "🌤"

def get_weather(city="深圳"):
    import urllib.parse
    url = f"https://wttr.in/{urllib.parse.quote(city)}?format=%C+%t&lang=zh"
    for _ in range(2):
        try:
            r = subprocess.run(
                ["curl", "-s", "-m", "6", "-L", url],
                capture_output=True, text=True, timeout=10)
            out = r.stdout.strip()
            if out and len(out) < 50 and "Unknown" not in out and "ERROR" not in out:
                # 翻译成中文
                out = _translate_weather(out)
                return _weather_emoji(out) + " " + out
        except:
            pass
        time.sleep(1)
    return "🌤 天气未知"

def _translate_weather(text):
    """将英文天气翻译成中文"""
    t = text.lower()
    mapping = [
        ("thunderstorm", "雷暴"), ("thunder", "雷阵雨"),
        ("heavy rain", "大雨"), ("light rain", "小雨"), ("moderate rain", "中雨"),
        ("patchy rain", "阵雨"), ("drizzle", "毛毛雨"), ("rain", "雨"),
        ("heavy snow", "大雪"), ("light snow", "小雪"), ("snow", "雪"),
        ("sleet", "雨夹雪"),
        ("clear", "晴天"), ("sunny", "晴天"),
        ("partly cloudy", "多云"), ("cloudy", "阴天"), ("overcast", "阴天"),
        ("fog", "雾"), ("mist", "薄雾"), ("haze", "霾"),
        ("blizzard", "暴风雪"), ("windy", "大风"),
    ]
    for eng, chn in mapping:
        if eng in t:
            import re
            temp_match = re.search(r'([+-]?\d+)°?([CcFf])?', text)
            if temp_match:
                sign = temp_match.group(1)[0] if temp_match.group(1)[0] in "+-" else ""
                num = temp_match.group(1).lstrip("+-")
                if sign == "-":
                    return f"{chn} 零下{num}摄氏度"
                else:
                    return f"{chn} {num}摄氏度"
            return chn
    return text

# ══════ 语音 ══════
# 默认人声
_DEFAULT_VOICE = "云希"

_voice_name = _DEFAULT_VOICE
_voice_rate = 240
_voice_volume = 60

# edge-tts 中文人声映射（友好名 → 接口名）
EDGE_VOICES = {
    "晓晓": "zh-CN-XiaoxiaoNeural",
    "晓伊": "zh-CN-XiaoyiNeural",
    "云希": "zh-CN-YunxiNeural",
    "云剑": "zh-CN-YunjianNeural",
    "云夏": "zh-CN-YunxiaNeural",
    "云扬": "zh-CN-YunyangNeural",
}

# 语气助词，随机添加到句尾让语音更亲切
_EMO_PARTICLES = ["呀", "哦", "呢", "啦", "哟", "嘛"]

# TTS 缓存目录（避免重复生成）
_TTS_CACHE_DIR = Path("/tmp/.xiaotang_tts_cache")
_TTS_CACHE_DIR.mkdir(parents=True, exist_ok=True)

def _tts_cache_path(text, voice, rate):
    """基于文本+语音+语速生成缓存路径"""
    key = f"{text}|{voice}|{rate}"
    h = hashlib.md5(key.encode()).hexdigest()
    return _TTS_CACHE_DIR / f"{h}.mp3"

def _add_particles(text):
    """在句尾加语气助词，基于文本哈希决定，保证缓存稳定"""
    h = hashlib.md5(text.encode()).hexdigest()
    if int(h[:8], 16) % 100 >= 35:
        return text
    p = _EMO_PARTICLES[int(h[8:16], 16) % len(_EMO_PARTICLES)]
    idx = text.rfind("！")
    if idx >= 0 and text[idx-1] not in _EMO_PARTICLES:
        text = text[:idx] + p + text[idx:]
    elif not text.endswith(tuple(_EMO_PARTICLES)):
        text = text + p
    return text

# ─── 语音播放队列（逐个播放，Event 唤醒零延迟）──
# 空闲时直接播放缓存语音，不排队；忙时排队等候
_voice_queue = []
_voice_queue_lock = threading.Lock()
_voice_queue_event = threading.Event()
_voice_worker_started = False
_voice_busy = False
_voice_busy_lock = threading.Lock()

def _is_voice_busy():
    with _voice_busy_lock:
        return _voice_busy

def _set_voice_busy(val):
    global _voice_busy
    with _voice_busy_lock:
        _voice_busy = val

def _play_voice_file(path):
    """播放语音文件，完成后释放忙标志"""
    _set_voice_busy(True)
    try:
        subprocess.run(["afplay", str(path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except:
        pass
    _set_voice_busy(False)

def _try_play_direct(path):
    """队列空闲时直接播放，返回 True。队列忙时返回 False 不走队列。"""
    with _voice_busy_lock:
        if _voice_busy or _voice_queue:
            return False
        _voice_busy = True
    threading.Thread(target=_play_voice_file, args=(path,), daemon=True).start()
    return True

def _enqueue_voice(path):
    """将语音加入播放队列，由后台线程逐个播放"""
    global _voice_worker_started
    with _voice_queue_lock:
        _voice_queue.append(str(path))
    _voice_queue_event.set()
    if not _voice_worker_started:
        _voice_worker_started = True
        threading.Thread(target=_voice_worker, daemon=True).start()

def _voice_worker():
    while True:
        _voice_queue_event.wait()
        _voice_queue_event.clear()
        while True:
            path = None
            with _voice_queue_lock:
                if _voice_queue:
                    path = _voice_queue.pop(0)
            if path:
                _play_voice_file(path)
            else:
                break

def speak(text):
    # 去除 emoji
    clean = re.sub(
        r'[\U00010000-\U0010ffff\U00002702-\U000027B0'
        r'\U0001f000-\U0001faff\U00002600-\U000026ff]',
        '', text, flags=re.UNICODE).strip()
    if not clean:
        return
    # 去除特殊符号
    clean = re.sub(r'[~～♡♥♪♫❤★☆✨💕🌸]', '', clean)
    # 添加语气助词
    clean = _add_particles(clean)
    # 添加停顿
    clean = re.sub(r'([。！？])', r'，', clean)
    if _voice_volume == 0:
        return
    try:
        voice = EDGE_VOICES.get(_voice_name, "zh-CN-YunxiNeural")
        rate_pct = int((_voice_rate - 240) / 240 * 100)
        rate_str = f"{rate_pct:+d}%"
        cache_path = _tts_cache_path(clean, voice, rate_str)

        if cache_path.exists():
            # 缓存命中：空闲时直接播放零延迟，忙时排队等待
            if not _try_play_direct(cache_path):
                _enqueue_voice(cache_path)
        else:
            # 未缓存 → 后台生成，生成后加入播放队列
            def _gen_play():
                try:
                    async def _do():
                        tts = edge_tts.Communicate(clean, voice=voice, rate=rate_str)
                        await tts.save(str(cache_path))
                    asyncio.run(_do())
                    if cache_path.exists():
                        _enqueue_voice(cache_path)
                except Exception as _e:
                    log(f"TTS 生成失败: {_e}")
            threading.Thread(target=_gen_play, daemon=True).start()
    except:
        pass

# macOS 系统音效映射（保证每台 Mac 都有）
_SFX_MAP = {
    "start":    "/System/Library/Sounds/Bottle.aiff",
    "complete": "/System/Library/Sounds/Glass.aiff",
    "cancel":   "/System/Library/Sounds/Pop.aiff",
    "open":     "/System/Library/Sounds/Bottle.aiff",
    "save":     "/System/Library/Sounds/Tink.aiff",
    "add":      "/System/Library/Sounds/Pop.aiff",
    "glass":    "/System/Library/Sounds/Glass.aiff",
    "hero":     "/System/Library/Sounds/Hero.aiff",
    "bottle":   "/System/Library/Sounds/Bottle.aiff",
    "funk":     "/System/Library/Sounds/Funk.aiff",
    "greet":    "/System/Library/Sounds/Bottle.aiff",
    "purr":     "/System/Library/Sounds/Purr.aiff",
}

def _play_sfx(name):
    """播放系统音效（异步，不阻塞）"""
    path = _SFX_MAP.get(name)
    if path:
        threading.Thread(target=lambda: subprocess.run(
            ["afplay", str(path)],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL),
            daemon=True).start()

# ══════ 气泡（动态适配 + 语音同步）══════

class BubblePanel:
    def __init__(self, cat_win, tk_root):
        self._cat_win    = cat_win
        self._root       = tk_root
        self._panel      = None
        self._lbl        = None
        self._aid_type   = None
        self._aid_close  = None
        self._full_txt   = ""
        self._char_idx   = 0
        self._on_done    = None

    def show(self, text, on_done=None):
        self._cancel_timers()
        if self._panel:
            try:
                self._panel.orderOut_(None)
            except:
                pass
            self._panel = None

        self._on_done  = on_done
        self._full_txt = text
        self._char_idx = 0
        log(f"气泡: {text[:30]}{'...' if len(text)>30 else ''}")

        # 动态计算尺寸：根据文字长度
        text_len = len(text)
        max_chars_per_line = 16
        lines = max(1, (text_len + max_chars_per_line - 1) // max_chars_per_line)
        lines = min(lines, 4)  # 最多4行
        BW = min(280, max(120, text_len * 12 + 50))
        BH = lines * 22 + 28

        try:
            # 使用 nonactivatingPanel 样式（与小猫窗口一致，确保全屏可见）
            style = AppKit.NSWindowStyleMaskBorderless | (1 << 7)
            panel = AppKit.NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
                AppKit.NSMakeRect(0, 0, BW, BH),
                style,
                AppKit.NSBackingStoreBuffered, False)
            panel.setOpaque_(False)
            panel.setBackgroundColor_(AppKit.NSColor.clearColor())
            panel.setHasShadow_(True)
            panel.setLevel_(AppKit.NSFloatingWindowLevel + 1)
            panel.setIgnoresMouseEvents_(True)
            panel.setHidesOnDeactivate_(False)
            panel.setFloatingPanel_(True)
            _safe_collection_behavior(panel)

            bg = _BubbleBGView.alloc().initWithFrame_(
                AppKit.NSMakeRect(0, 0, BW, BH))

            # 正文
            lbl = _ns_label("")
            if lbl:
                try:
                    lbl.setTextColor_(
                        AppKit.NSColor.colorWithCalibratedWhite_alpha_(1.0, 1.0))
                except:
                    pass
                try:
                    lbl.setFont_(AppKit.NSFont.systemFontOfSize_(13))
                except:
                    pass
                try:
                    lbl.setMaximumNumberOfLines_(4)
                except:
                    pass
                try:
                    lbl.setLineBreakMode_(0)
                except:
                    pass
                lbl.setFrame_(AppKit.NSMakeRect(12, 8, BW - 24, BH - 16))
                bg.addSubview_(lbl)

            panel.setContentView_(bg)

            # 定位：猫咪正上方
            try:
                cf  = self._cat_win.frame()
                bx  = cf.origin.x + cf.size.width / 2 - BW / 2
                by  = cf.origin.y + cf.size.height + 8
                scr = AppKit.NSScreen.mainScreen().frame()
                bx  = max(8, min(bx, scr.size.width - BW - 8))
                by  = min(by, scr.size.height - BH - 8)
                panel.setFrameOrigin_((bx, by))
            except:
                pass

            panel.orderFrontRegardless()
            self._panel = panel
            self._lbl   = lbl

        except Exception as e:
            log(f"气泡创建失败: {e}")
            self._panel = None
            self._lbl   = None

        self._typewrite()

    def _cancel_timers(self):
        for attr in ("_aid_type", "_aid_close"):
            aid = getattr(self, attr, None)
            if aid:
                try:
                    self._root.after_cancel(aid)
                except:
                    pass
            setattr(self, attr, None)

    def _typewrite(self):
        if self._char_idx < len(self._full_txt):
            ch = self._full_txt[self._char_idx]
            self._char_idx += 1
            if self._lbl:
                try:
                    self._lbl.setStringValue_(self._full_txt[:self._char_idx])
                except:
                    pass
            delay = 60 if ch in "，。！？,.!?~～" else 30
            self._aid_type = self._root.after(delay, self._typewrite)
        else:
            # 文字显示完成后，等待语音读完再关闭
            # edge-tts 生成~1.5s + 朗读~0.15s/字 + 缓冲
            speak_duration = 2.5 + len(self._full_txt) * 0.15
            speak_ms = int(speak_duration * 1000)
            wait = max(4000, min(speak_ms, 18000))
            self._aid_close = self._root.after(wait, self._close)

    def _close(self):
        self._cancel_timers()
        if self._panel:
            try:
                self._panel.orderOut_(None)
            except:
                pass
            self._panel = None
        cb = self._on_done
        self._on_done = None
        if cb:
            # 延迟0.3秒再显示下一个气泡
            try:
                self._root.after(300, cb)
            except:
                pass

    def close_now(self):
        self._close()

# ══════ 数据管理 ══════
DEFAULT_TEMPLATES = [
    {"title": "家长接送沟通",        "start_time": "08:00", "duration": 20},
    {"title": "团队例会",            "start_time": "09:00", "duration": 30},
    {"title": "家长到访接待",        "start_time": "09:30", "duration": 60},
    {"title": "新家长咨询接待",      "start_time": "10:00", "duration": 45},
    {"title": "销售跟进电话",        "start_time": "11:00", "duration": 30},
    {"title": "家长满意度回访",      "start_time": "13:30", "duration": 30},
    {"title": "个案评估观察",        "start_time": "14:00", "duration": 60},
    {"title": "课程体验安排",        "start_time": "15:00", "duration": 45},
    {"title": "排课与课表调整",      "start_time": "16:00", "duration": 30},
    {"title": "家长接送沟通",        "start_time": "17:00", "duration": 20},
]

# ══════ 打招呼随机语 ══════
_GREETING_PRAISE = [
    "今天状态真好，神采飞扬！",
    "今天漂亮又干练，太棒了！",
    "今天的穿搭很有品味！",
    "今天精神饱满，充满活力！",
    "笑容很温暖，看了就让人开心！",
    "今天格外有魅力！",
    "今天看起来很厉害的样子！",
    "今天心情不错，我也开心！",
    "今天气色真好，容光焕发！",
    "今天就是全场的焦点！",
    "今天优雅大方，气质出众！",
    "举手投足间都散发着自信！",
    "今天的状态让人眼前一亮！",
    "今天的发型很适合你！",
    "今天说话的语气特别温柔！",
    "今天做事特别利落！",
    "今天认真工作的样子很迷人！",
    "今天的笑容特别灿烂！",
    "非常聪明又有才华！",
    "总是能给人带来惊喜！",
    "品味一直都很在线！",
    "今天红光满面，气色好极了！",
    "今天的妆容精致又自然！",
    "今天的眼神特别有神采！",
    "今天气场强大，镇得住场！",
    "总是能把事情处理得井井有条！",
    "想法总是很有创意！",
    "今天看起来心情特别好！",
    "今天的举止特别优雅！",
    "身上有一种独特的魅力！",
    "今天格外耀眼夺目！",
    "总是那么温柔体贴！",
    "今天的表现特别出色！",
    "天生就是做大事的人！",
    "有一种让人安心的力量！",
    "今天格外美丽动人！",
]
_GREETING_ENCOURAGE = [
    "加油，你是最棒的！",
    "一定行，没有什么可以难倒你！",
    "坚持下去，胜利就在前方！",
    "今天也要元气满满！",
    "不要怕，大胆去做，我支持你！",
    "每一步都在进步，很棒！",
    "今天的工作一定顺顺利利！",
    "相信自己，你可以的！",
    "今天也要全力以赴！",
    "不管做什么都会成功的！",
    "今天也要加油努力！",
    "困难只是暂时的！",
    "你有无限的潜力！",
    "勇敢追求自己想要的一切！",
    "你是自己人生的主角！",
    "不要给自己太大压力！",
    "放轻松，一切都会好起来的！",
    "你比你想象中更强大！",
    "每一次尝试都是成长！",
    "好运气正在向你赶来！",
    "努力的人运气不会太差！",
    "再坚持一下就能看到曙光！",
    "你可以成为任何你想成为的人！",
    "别着急，好的都在后面！",
    "相信过程，结果自然不会差！",
    "你已经做得很好了！",
    "保持积极的心态最重要！",
    "慢慢来，不用急！",
    "你的努力一定会被看见！",
    "今天也要开开心心的！",
    "深呼吸，一切都会顺利的！",
    "未来可期，加油！",
    "今天也是充满希望的一天！",
    "朝着目标前进吧！",
    "每天进步一点点就是成功！",
    "幸福就在努力的路上！",
]
_GREETING_BLESS = [
    "祝今天万事如意，心想事成！",
    "祝身体健康，百病不侵！",
    "祝开心每一天，笑容常在！",
    "祝财源广进，钱包鼓鼓！",
    "祝工作顺利，步步高升！",
    "祝好运连连，惊喜不断！",
    "祝天天好心情，事事都顺心！",
    "祝吃好喝好，长生不老！",
    "祝一路平安，诸事顺遂！",
    "祝幸福快乐，永远被爱！",
    "祝今天收获满满！",
    "祝遇到的都是好事！",
    "祝梦想成真，前程似锦！",
    "祝今天也有好运气！",
    "祝烦恼全部消失！",
    "祝每天都能睡个好觉！",
    "祝胃口好，吃饭香！",
    "祝越来越年轻漂亮！",
    "祝每天都充满阳光和能量！",
    "祝笑口常开，烦恼走开！",
    "祝邂逅美好的事物！",
    "祝生活美满，家庭幸福！",
    "祝天天都有小惊喜！",
    "祝顺利度过每一个难关！",
    "祝身边都是温暖的人！",
    "祝未来的路越走越宽！",
    "祝平安喜乐，岁月静好！",
    "祝好事成双，快乐加倍！",
    "祝每一天都比昨天更好！",
    "祝被世界温柔以待！",
    "祝事业蒸蒸日上！",
    "祝想要的都拥有！",
    "祝健康平安，一生顺遂！",
    "祝永远保持好心情！",
    "祝今天也有小确幸！",
    "祝一切安好，幸福常伴！",
]
_GREETING_HAPPY = [
    "今天也是美好的一天！",
    "和你在一起的每一天都很开心！",
    "今天天气不错，心情也要美美的！",
    "今天有没有什么开心的事分享呀？",
    "每次见到你都特别开心！",
    "今天也是元气满满的一天呢！",
    "希望每一天都充满阳光！",
    "你开心我就开心，所以要开心哦！",
    "今天也要微笑面对一切！",
    "日子过得真快，珍惜每一天！",
    "今天又是崭新的一天！",
    "生活很美好，值得好好享受！",
    "今天的阳光格外温暖！",
    "今天心情好好，想唱歌！",
    "今天的风和日丽，适合出去走走！",
    "今天感觉自己特别棒！",
    "今天也是活力四射的一天！",
    "人生得意须尽欢！",
    "今天要对自己好一点！",
    "开心也是一天，不开心也是一天！",
    "今天有没有什么有趣的事情？",
    "今天的心情像彩虹一样绚烂！",
    "每天都是新的开始！",
    "今天也要做个快乐的小可爱！",
    "生活不仅有眼前的苟且，还有诗和远方！",
    "今天适合喝杯咖啡，放松一下！",
    "今天的幸福指数很高！",
    "今天也是被幸运眷顾的一天！",
    "今天要做自己喜欢的事！",
    "今天的快乐是双倍的！",
    "今天和昨天不一样，值得期待！",
    "今天也要好好爱自己！",
    "今天的空气都是甜的！",
    "保持热爱，奔赴山海！",
    "生活明朗，万物可爱！",
    "今天也要甜甜的！",
]

class DataManager:
    def __init__(self):
        self.data = {
            "schedules": [], "history": [], "notes": {},
            "templates": [t.copy() for t in DEFAULT_TEMPLATES],
            "event_counts": {},
            "voice": {"name": _DEFAULT_VOICE, "rate": 240, "volume": 60},
            "pet_name": "小唐",
        }
        self._load()
        # 强制重置模板为最新默认值
        self.data["templates"] = [t.copy() for t in DEFAULT_TEMPLATES]
        # 确保语音设置存在
        if "voice" not in self.data:
            self.data["voice"] = {"name": _DEFAULT_VOICE, "rate": 240, "volume": 60}
        if "pet_name" not in self.data:
            self.data["pet_name"] = "小唐"

    def _load(self):
        if DATA_FILE.exists() and DATA_FILE.stat().st_size > 0:
            try:
                with open(DATA_FILE, "r", encoding="utf-8") as f:
                    self.data.update(json.load(f))
            except Exception as e:
                log(f"数据加载失败: {e}")
        # 同步语音设置到全局变量
        self._sync_voice()

    def _sync_voice(self):
        global _voice_name, _voice_rate, _voice_volume
        v = self.data.get("voice", {})
        _voice_name = v.get("name", _DEFAULT_VOICE)
        _voice_rate = v.get("rate", 240)
        _voice_volume = v.get("volume", 60)

    def set_voice(self, name, rate, volume=None):
        v = {"name": name, "rate": rate}
        if volume is not None:
            v["volume"] = volume
        else:
            v["volume"] = self.data.get("voice", {}).get("volume", 80)
        self.data["voice"] = v
        self.save()
        self._sync_voice()

    def import_data(self, filepath):
        """导入JSON数据文件，合并到当前数据"""
        try:
            with open(filepath, "r", encoding="utf-8") as f:
                new_data = json.load(f)
            # 兼容两种格式：列表（导出格式）或字典（完整数据格式）
            if isinstance(new_data, list):
                # 列表格式：直接是日程列表
                schedules = new_data
                new_data = {"schedules": schedules}
            elif not isinstance(new_data, dict):
                return False, "文件格式错误"
            # 合并日程（去重：同id不重复添加）
            old_ids = {s["id"] for s in self.data.get("schedules", [])}
            new_count = 0
            for s in new_data.get("schedules", []):
                if s.get("id") and s["id"] not in old_ids:
                    self.data.setdefault("schedules", []).append(s)
                    new_count += 1
            # 合并历史
            self.data.setdefault("history", []).extend(new_data.get("history", []))
            # 合并笔记
            self.data.setdefault("notes", {}).update(new_data.get("notes", {}))
            # 合并模板
            old_titles = {t["title"] for t in self.data.get("templates", [])}
            for t in new_data.get("templates", []):
                if t.get("title") and t["title"] not in old_titles:
                    self.data.setdefault("templates", []).append(t)
            # 合并事件计数
            for k, v in new_data.get("event_counts", {}).items():
                self.data.setdefault("event_counts", {})[k] = \
                    self.data["event_counts"].get(k, 0) + v
            self.save()
            return True, f"导入成功！新增 {new_count} 条日程"
        except Exception as e:
            return False, f"导入失败: {e}"

    def save(self):
        try:
            with open(DATA_FILE, "w", encoding="utf-8") as f:
                json.dump(self.data, f, ensure_ascii=False, indent=2)
        except Exception as e:
            log(f"数据保存失败: {e}")

    def add_schedule(self, title, start_time, dur, date=None):
        date = date or datetime.date.today().isoformat()
        item = {"id": int(time.time() * 1000), "title": title,
                "start_time": start_time, "duration": dur,
                "date": date, "alerted": False, "completed": False}
        self.data["schedules"].append(item)
        cnt = self.data["event_counts"].get(title, 0) + 1
        self.data["event_counts"][title] = cnt
        titles = [t["title"] if isinstance(t, dict) else t
                  for t in self.data["templates"]]
        if cnt >= 10 and title not in titles:
            self.data["templates"].append(
                {"title": title, "start_time": start_time, "duration": dur})
        self.data["history"].append(
            {"title": title, "start_time": start_time,
             "duration": dur, "date": date})
        self.save()
        return item

    def today_schedules(self):
        today = datetime.date.today().isoformat()
        return [s for s in self.data["schedules"] if s["date"] == today]

    def schedules_in_range(self, d0, d1):
        return [s for s in self.data["schedules"] if d0 <= s["date"] <= d1]

    def get_note(self, d): return self.data["notes"].get(d, "")
    def set_note(self, d, t): self.data["notes"][d] = t; self.save()

    def mark_alerted(self, item_id):
        for s in self.data["schedules"]:
            if s["id"] == item_id:
                s["alerted"] = True
        self.save()

    def export_range(self, d0, d1):
        lines = [f"📅 小唐日程  {d0} ~ {d1}", "=" * 38]
        rows  = sorted(self.schedules_in_range(d0, d1),
                       key=lambda x: (x["date"], x["start_time"]))
        cur = None
        noted = set()
        for s in rows:
            if s["date"] != cur:
                cur = s["date"]
                lines.append(f"\n▸ {cur}")
            lines.append(f"  {s['start_time']}  {s['title']}  ({s['duration']}min)")
        for s in rows:
            if s["date"] not in noted:
                noted.add(s["date"])
                n = self.get_note(s["date"])
                if n.strip():
                    lines.append(f"  📝 {n.strip()}")
        if not rows:
            lines.append("  （该时间段暂无日程）")
        return "\n".join(lines)

# ══════ 同步到备忘录 ══════
def sync_to_notes(dm):
    """将当月所有日程写入macOS备忘录，每条日程按日期分组，不使用合并逻辑避免格式混乱"""
    try:
        today = datetime.date.today()
        today_str = today.isoformat()
        month_prefix = today_str[:7]  # "2026-05"
        month_str = today.strftime("%Y年%m月")
        pet_name = dm.data.get("pet_name", "小唐")
        note_name = f"{pet_name}{month_str}事项"

        # 取当月所有日程，按日期分组
        month_items = [s for s in dm.data.get("schedules", []) if s.get("date", "").startswith(month_prefix)]
        by_date = {}
        for s in month_items:
            d = s["date"]
            if d not in by_date:
                by_date[d] = []
            by_date[d].append(s)

        # 按日期升序生成块
        sep = "-" * 32
        blocks = []
        for date_str in sorted(by_date.keys()):
            items = sorted(by_date[date_str], key=lambda x: x.get("start_time", "00:00"))
            tag = f"[{date_str}]"
            lines = [f"<b>{sep}</b>", f"<b>{tag}</b>"]
            for s in items:
                chk = "✅" if s.get("completed") else "⬜"
                lines.append(f"{chk} {s['start_time']} {s['title']} ({s['duration']}分钟)")
            lines.append(f"<b>{sep}</b>")
            blocks.append("<br/>".join(lines))

        new_body = "<br/><br/>".join(blocks)
        # 自动前置标题：小唐2026年05月日程本
        note_title = f"{pet_name}{month_str}日程本"
        new_body = f"<h2>{note_title}</h2><br/>{new_body}"
        html_full = f"<html><body style='font-family:Helvetica;font-size:13px'>{new_body}</body></html>"

        tmp_new = Path.home() / ".xiaotang_note_new"
        tmp_new.write_text(html_full, encoding="utf-8")

        write_script = f'''
        tell application "Notes"
            set noteName to "{note_name}"
            set noteHtml to (do shell script "cat {tmp_new}")
            try
                set theNote to first note whose name is noteName
                set body of theNote to noteHtml
            on error
                make new note with properties {{name:noteName, body:noteHtml}}
            end try
        end tell
        '''
        subprocess.run(["osascript", "-e", write_script], capture_output=True, timeout=10)
        tmp_new.unlink(missing_ok=True)
        return True
    except Exception as e:
        log(f"同步备忘录失败: {e}")
        return False

# ══════ 完成播报 ══════
def _completion_text(dm):
    """根据完成状态返回合适的播报文本"""
    today = datetime.date.today().isoformat()
    items = [s for s in dm.data.get("schedules", []) if s.get("date") == today]
    if not items:
        return "真厉害！"
    done_count = sum(1 for s in items if s.get("completed"))
    total = len(items)
    if done_count == total:
        return "全部完成，收工！"
    if done_count == 1:
        return "今日首项已完成！"
    return "真厉害！"

# ══════ 主程序 ══════
class XiaoTang:
    SIZE = 192
    FIXED_REMINDERS = [
        ("10:00", "记得喝水休息一下哦~ 💧"),
        ("12:00", "下班休息喽！记得吃午餐哟！🍱"),
        ("13:55", "快起床清醒一下，下午又是元气满满的开始！"),
        ("15:30", "记得喝水休息，站起来活动活动~ 🧘"),
        ("17:00", "可以放松一下了，顺便做做今日总结吧！📝"),
        ("18:00", "又是完美的一天，收工回家喽！🎉"),
    ]
    IDLE_QUOTES = [
        "在认真工作呢~ 🌟",
        "有什么需要帮忙的吗？",
        "今天辛苦啦，多喝水哦！",
        "最喜欢你了 💕",
        "要不要休息一下眼睛呀？",
        "加油加油！最棒了！✨",
        "时间过得好快，注意休息哟~",
    ]
    def __init__(self):
        log("=== 小唐 v5.0.2 启动 ===")

        # 全部属性先初始化，防止任何地方 AttributeError
        self._state          = "idle"
        self._anim_state     = "idle"
        self._frame_idx      = 0
        self._anim_job       = None
        self._frames         = {}
        self._last_event_t   = time.time()
        self._last_activity  = time.time()
        self._screen_on      = True
        self._bubble_queue   = []
        self._bubble_busy    = False
        self._fired_reminders = set()
        self._fired_schedules = set()
        self._schedule_end_timers = {}  # {item_id: timer_id} 跟踪日程结束时间
        self._pending_done_question = None  # 待回答的"做完了？"问题标题
        self._pending_done_item_id = None   # 对应的日程 ID
        self._attention_until = 0            # 注意力动画截止时间戳
        self.ACTIVE_TIMEOUT  = 1
        self.SLEEP_TIMEOUT   = 300
        self.dm              = DataManager()

        # Tk 隐藏（仅做 after 调度 + Toplevel 父窗口）
        self.root = tk.Tk()
        self.root.withdraw()

        self._setup_window()
        self._load_frames()
        self._start_anim()

        # 键盘监听
        self._start_pynput()

        threading.Thread(target=self._reminder_loop,    daemon=True).start()
        threading.Thread(target=self._random_chat_loop, daemon=True).start()
        threading.Thread(target=self._auto_sync_loop,   daemon=True).start()
        threading.Thread(target=self._precache_tts,    daemon=True).start()

        self.root.after(500,  self._update_state)
        self.root.after(500,  self._poll_clicks)
        self.root.after(2500, self._morning_greeting)
        self._register_autostart()

        log("mainloop 启动")
        self.root.mainloop()

    # ─── 窗口 ───────────────────────────────
    def _setup_window(self):
        global _current_img
        try:
            screen = AppKit.NSScreen.mainScreen().visibleFrame()
            sz = self.SIZE
            wx = screen.origin.x + screen.size.width - sz - 20
            wy = screen.origin.y + 50

            # 使用 NSPanel + nonactivatingPanel 样式（参考 sema-code）
            # NSWindowStyleMaskNonactivatingPanel = 1 << 7 = 128
            style = AppKit.NSWindowStyleMaskBorderless | (1 << 7)
            win = _CatWindow.alloc().initWithContentRect_styleMask_backing_defer_(
                AppKit.NSMakeRect(wx, wy, sz, sz),
                style,
                AppKit.NSBackingStoreBuffered, False)
            win.setOpaque_(False)
            win.setBackgroundColor_(AppKit.NSColor.clearColor())
            win.setHasShadow_(False)
            win.setLevel_(AppKit.NSFloatingWindowLevel)  # 浮动层级
            win.setIgnoresMouseEvents_(False)
            win.setHidesOnDeactivate_(False)
            win.setFloatingPanel_(True)
            _safe_collection_behavior(win)

            # 左键点击由 _poll_clicks 轮询处理，不从 AppKit 回调直接调用 tkinter

            cv = _ContentView.alloc().initWithFrame_(
                AppKit.NSMakeRect(0, 0, sz, sz))
            win.setContentView_(cv)
            win.orderFrontRegardless()
            try:
                AppKit.NSApplication.sharedApplication().activateIgnoringOtherApps_(True)
            except: pass

            self._win     = win
            self._content = cv
            self._bubble  = BubblePanel(win, self.root)
            log("窗口创建成功")

        except Exception as e:
            log(f"_setup_window 失败: {e}")
            import traceback
            log(traceback.format_exc())
            sys.exit(1)

    def _safe_after(self, fn):
        try:
            self.root.after(0, fn)
        except Exception as e:
            log(f"_safe_after: {e}")

    def _poll_clicks(self):
        """轮询 NSWindow 的点击标志位，安全地在 tkinter 线程中处理"""
        try:
            if self._win._left_click_pending:
                self._win._left_click_pending = False
                self._show_cat_menu()
            if self._win._right_click_pending:
                self._win._right_click_pending = False
                self._show_cat_menu()
            # 处理菜单点击
            tag = self._win._menu_click_tag
            if tag >= 0:
                should_close = self._win._menu_should_close
                self._win._menu_click_tag = -1
                self._win._menu_should_close = True
                if hasattr(self._win, '_menu_actions') and tag < len(self._win._menu_actions):
                    action = self._win._menu_actions[tag]
                    if callable(action):
                        try:
                            self._flash_attention()
                            action()
                        except Exception as e:
                            log(f"菜单动作错误: {e}")
                # 关闭菜单（已完成折叠除外）
                if should_close and self._cat_menu_win:
                    try:
                        self._cat_menu_win.orderOut_(None)
                    except:
                        pass
                    self._cat_menu_win = None
        except Exception as e:
            log(f"_poll_clicks: {e}")
        self.root.after(100, self._poll_clicks)

    _cat_menu_win = None  # 当前菜单窗口

    _show_completed = False  # 是否展开已完成

    def _show_cat_menu(self):
        """左键点击小猫弹出菜单"""
        if self._cat_menu_win:
            try: self._cat_menu_win.orderOut_(None)
            except: pass
            self._cat_menu_win = None

        try:
            # 用 NSCustomPanel 替代 tkinter，完全不抢焦点
            style = AppKit.NSWindowStyleMaskBorderless | (1 << 7)
            panel = AppKit.NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
                AppKit.NSMakeRect(0, 0, 220, 400),
                style,
                AppKit.NSBackingStoreBuffered, False)
            panel.setOpaque_(True)
            panel.setBackgroundColor_(AppKit.NSColor.colorWithCalibratedWhite_alpha_(0.1, 0.94))
            panel.setHasShadow_(True)
            panel.setLevel_(AppKit.NSFloatingWindowLevel + 1)
            panel.setIgnoresMouseEvents_(False)
            panel.setHidesOnDeactivate_(False)
            panel.setFloatingPanel_(True)
            _safe_collection_behavior(panel)
            self._cat_menu_win = panel

            # 内容视图
            cv = AppKit.NSView.alloc().initWithFrame_(AppKit.NSMakeRect(0, 0, 220, 400))
            panel.setContentView_(cv)

            # 构建所有菜单项
            rows = []  # [(text, action), ...]
            if self._pending_done_question:
                t = self._pending_done_question
                rows.append((f"✅ 做完了「{t}」", self._done_yes))
                rows.append(("⏰ 还没，再给1小时", self._done_no))
            else:
                # 💬 打招呼（日期+天气+节日）
                def _greeting():
                    now = datetime.datetime.now()
                    ds = now.strftime("%Y年%m月%d日")
                    wds = ["星期一","星期二","星期三","星期四","星期五","星期六","星期日"]
                    wd = wds[now.weekday()]
                    h = now.hour
                    time_word = "早上" if 5 <= h < 12 else "上午" if h < 12 else "中午" if h < 14 else "下午" if h < 18 else "晚上"
                    holiday = _get_holiday()
                    holiday_text = f"，{holiday}快乐" if holiday else ""
                    try:
                        weather = get_weather("深圳")
                    except:
                        weather = "天气未知"
                    extra = ""
                    if now.weekday() == 4:
                        extra = "终于周五了，马上就可以休息了。"
                    elif now.weekday() == 5:
                        extra = "今天是周六，加班辛苦啦。"
                    msg = f"{time_word}好呀！今天是{ds}{wd}{holiday_text}。天气{weather}。{extra}主人要天天开心，你会越来越顺滴！"
                    self._enqueue(msg)
                rows.append(("💬 打招呼", _greeting))

                # 四个语录板块
                # 一行展示四个板块，每个可独立点击
                def _cat_click(cl_list):
                    self._enqueue(random.choice(cl_list))
                rows.append(("c4", _cat_click))  # 特殊标记"c4"，行绘制时特殊处理

            # 语音设置（固定在第2个位置，tag=1）
            v = self.dm.data.get("voice", {})
            vn = v.get("name", _DEFAULT_VOICE)
            spd = v.get("rate", 240)
            vol = v.get("volume", 60)
            spd_vals = {"慢":150,"中":210,"中快":240,"快":270,"极快":300}
            vol_vals = {"静音":0,"低":30,"中":60,"高":80,"最大":100}
            spd_l = next((k for k, val in spd_vals.items() if val == spd), "中快")
            vol_l = next((k for k, val in vol_vals.items() if val == vol), "中")
            def _voice_settings():
                log("打开语音设置")
                pop = tk.Toplevel(self.root)
                pop.title("语音设置")
                pop.configure(bg="#151515")
                pop.overrideredirect(True)
                pop.attributes("-topmost", True)
                # 定位在菜单右侧（屏幕内）
                cf = self._win.frame()
                scr = AppKit.NSScreen.mainScreen().frame()
                px = int(cf.origin.x + cf.size.width + 6)
                py = int(scr.size.height - cf.origin.y - cf.size.height + cf.size.height/2 - 90)
                if px + 200 > scr.size.width - 10:
                    px = int(cf.origin.x - 206)
                if py < 40:
                    py = 40
                pop.geometry(f"200x180+{px}+{py}")
                # 点击外部自动关闭
                def _pop_check_close():
                    if not pop.winfo_exists():
                        return
                    try:
                        mp = AppKit.NSEvent.mouseLocation()
                        scre = AppKit.NSScreen.mainScreen().frame()
                        gx = px
                        gy_tk = py
                        gy_mac = int(scre.size.height - gy_tk - 180)
                        if not (gx <= mp.x <= gx + 200 and gy_mac <= mp.y <= gy_mac + 180):
                            if AppKit.NSEvent.pressedMouseButtons() & 1:
                                try: pop.destroy()
                                except: pass
                                return
                    except:
                        pass
                    if pop.winfo_exists():
                        pop.after(150, _pop_check_close)
                pop.after(300, _pop_check_close)
                # 标题
                tk.Label(pop, text="语音设置", bg="#151515", fg="#87CEEB",
                         font=("PingFang SC", 13, "bold")).pack(pady=(8, 2))
                # 人声
                v_voice = tk.StringVar(value=vn)
                f1 = tk.Frame(pop, bg="#151515"); f1.pack(padx=14, pady=2)
                tk.Label(f1, text="人声", bg="#151515", fg="#aaa",
                         font=("PingFang SC", 10)).pack(side="left")
                cb_voice = ttk.Combobox(f1, textvariable=v_voice,
                    values=list(EDGE_VOICES.keys()),
                    width=8, state="readonly")
                cb_voice.pack(side="left", padx=4)
                # 语速
                v_spd = tk.StringVar()
                f2 = tk.Frame(pop, bg="#151515"); f2.pack(padx=14, pady=2)
                tk.Label(f2, text="语速", bg="#151515", fg="#aaa",
                         font=("PingFang SC", 10)).pack(side="left")
                spd_items = [f"{k}({v})" for k,v in spd_vals.items()]
                cb_spd = ttk.Combobox(f2, textvariable=v_spd,
                    values=spd_items, width=10, state="readonly")
                cb_spd.pack(side="left", padx=4)
                cb_spd.set(f"{spd_l}({spd_vals[spd_l]})")
                # 音量
                v_vol = tk.StringVar()
                f3 = tk.Frame(pop, bg="#151515"); f3.pack(padx=14, pady=2)
                tk.Label(f3, text="音量", bg="#151515", fg="#aaa",
                         font=("PingFang SC", 10)).pack(side="left")
                vol_items = [f"{k}({v})" for k,v in vol_vals.items()]
                cb_vol = ttk.Combobox(f3, textvariable=v_vol,
                    values=vol_items, width=10, state="readonly")
                cb_vol.pack(side="left", padx=4)
                cb_vol.set(f"{vol_l}({vol_vals[vol_l]})")
                # 保存
                def _apply():
                    try:
                        sr = spd_vals[v_spd.get().split("(")[0]]
                        vr = vol_vals[v_vol.get().split("(")[0]]
                        self.dm.set_voice(v_voice.get(), sr, vr)
                        pop.destroy()
                    except Exception as e:
                        log(f"语音保存错误: {e}")
                tk.Button(pop, text="💾 保存", command=_apply,
                          bg="#333", fg="#87CEEB", font=("PingFang SC", 11),
                          relief="flat").pack(pady=6)
            rows.append((f"🔊 {vn} · {spd_l} · {vol_l}", _voice_settings))

            # 今日待办（已完成折叠）
            items = self.dm.today_schedules()
            if items:
                items_sorted = sorted(items, key=lambda x: x["start_time"])
                pend_items = [i for i in items_sorted if not i.get("completed")][:4]
                done_items = [i for i in items_sorted if i.get("completed")][:4]
                # 未完成
                for it in pend_items:
                    label = f"⬜ {it['start_time']} {it['title'][:4]}"
                    def _toggle(it=it):
                        it["completed"] = not it.get("completed", False)
                        self.dm.save()
                        if it["completed"]:
                            _play_sfx("complete")
                            speak(_completion_text(self.dm))
                    rows.append((label, _toggle))
                # 已完成折叠
                if done_items:
                    self._show_completed = getattr(self, '_show_completed', False)
                    arrow = "▼" if self._show_completed else "▶"
                    def _toggle_done():
                        self._win._menu_should_close = False
                        self._show_completed = not self._show_completed
                        self.root.after(50, self._show_cat_menu)
                    rows.append((f"{arrow} 已完成({len(done_items)})", _toggle_done))
                    if self._show_completed:
                        for it in done_items[:5]:
                            label = f"  ✅ {it['start_time']} {it['title'][:4]}"
                            def _untoggle(it=it):
                                it["completed"] = False
                                self.dm.save()
                                _play_sfx("cancel")
                            rows.append((label, _untoggle))

            rows.append(("📅 打开日程本", self._open_schedule))

            # 存储 actions 到 _win
            actions = [a for _, a in rows]
            self._win._menu_actions = actions

            # 计算面板高度
            row_h = 32
            panel_h = len(rows) * row_h + 8

            # 绘制按钮行
            for i, (text, action) in enumerate(rows):
                y = panel_h - (i + 1) * row_h - 4

                if text == "c4":
                    # 特殊行：四个板块（夸夸·鼓励·祝福·开心）一行展示
                    cats = [(_GREETING_PRAISE, None),
                            (_GREETING_ENCOURAGE, None),
                            (_GREETING_BLESS, None),
                            (_GREETING_HAPPY, None)]
                    cat_text = "❤️夸夸  鼓励  祝福  开心🎉"
                    lbl = AppKit.NSTextField.labelWithString_(cat_text)
                    lbl.setFrame_(AppKit.NSMakeRect(14, y + 6, 192, 20))
                    lbl.setFont_(AppKit.NSFont.boldSystemFontOfSize_(12))
                    lbl.setTextColor_(AppKit.NSColor.colorWithCalibratedRed_green_blue_alpha_(
                        0.53, 0.81, 0.92, 1.0))
                    cv.addSubview_(lbl)
                    # 4个独立点击覆盖
                    seg_w = 48
                    for ci, (cl, sfx) in enumerate(cats):
                        def _cat_f(cl=cl, sfx=sfx):
                            if sfx:
                                _play_sfx(sfx)
                            # 四个板块统一用 thinking.gif 持续 3 秒
                            if "thinking" in self._frames:
                                self._attention_until = time.time() + 3
                                self._state = "thinking"
                                self._anim_state = "thinking"
                                self._frame_idx = 0
                            self._enqueue(random.choice(cl))
                        btn = AppKit.NSButton.alloc().initWithFrame_(
                            AppKit.NSMakeRect(14 + ci * seg_w, y, seg_w, row_h))
                        btn.setBordered_(False)
                        btn.setTitle_("")
                        btn.setTarget_(self._win)
                        btn.setAction_("_menuTap:")
                        actions.append(_cat_f)
                        btn.setTag_(len(actions) - 1)
                        cv.addSubview_(btn)
                else:
                    # 标准文字标签
                    lbl = AppKit.NSTextField.labelWithString_(text)
                    lbl.setFrame_(AppKit.NSMakeRect(14, y + 6, 192, 20))
                    lbl.setFont_(AppKit.NSFont.boldSystemFontOfSize_(12))
                    lbl.setTextColor_(
                        AppKit.NSColor.colorWithCalibratedRed_green_blue_alpha_(
                            0.53, 0.81, 0.92, 1.0))
                    cv.addSubview_(lbl)

                    # 点击用透明按钮覆盖
                    btn = AppKit.NSButton.alloc().initWithFrame_(
                        AppKit.NSMakeRect(0, y, 220, row_h))
                    btn.setBordered_(False)
                    btn.setTitle_("")
                    btn.setTarget_(self._win)
                    btn.setAction_("_menuTap:")
                    btn.setTag_(i)
                    cv.addSubview_(btn)

                # 分隔线
                line = AppKit.NSBox.alloc().initWithFrame_(
                    AppKit.NSMakeRect(6, y, 208, 1))
                line.setBoxType_(2)
                line.setBorderColor_(
                    AppKit.NSColor.colorWithCalibratedWhite_alpha_(0.3, 1.0))
                cv.addSubview_(line)

            # 调整面板
            panel.setFrame_display_(
                AppKit.NSMakeRect(0, 0, 220, panel_h), True)

            # 定位到小猫左侧
            cf = self._win.frame()
            cat_x = int(cf.origin.x)
            cat_mid_y = int(cf.origin.y + cf.size.height / 2)
            bw = 220
            mx = cat_x - bw - 4
            my = cat_mid_y - panel_h // 2
            if mx < 8:
                mx = int(cf.origin.x + cf.size.width + 4)
            panel.setFrameOrigin_((mx, my))
            panel.orderFrontRegardless()

            # 点击外部关闭
            def _check_close():
                if not self._cat_menu_win:
                    return
                if panel != self._cat_menu_win:
                    return
                try:
                    mp = AppKit.NSEvent.mouseLocation()
                    gx = int(panel.frame().origin.x)
                    gy = int(panel.frame().origin.y)
                    gw = int(panel.frame().size.width)
                    gh = int(panel.frame().size.height)
                    if not (gx <= mp.x <= gx + gw and gy <= mp.y <= gy + gh):
                        if AppKit.NSEvent.pressedMouseButtons() & 1:
                            panel.orderOut_(None)
                            self._cat_menu_win = None
                            return
                except:
                    pass
                if self._cat_menu_win and panel == self._cat_menu_win:
                    self.root.after(150, _check_close)

            self.root.after(300, _check_close)

        except Exception as e:
            import traceback
            log(f"菜单弹出失败: {e}")
            log(traceback.format_exc())

    def _show_done_options(self):
        """日程结束时自动弹出完成选项"""
        if not self._pending_done_question:
            return
        self._show_cat_menu()

    def _done_yes(self):
        title = self._pending_done_question
        item_id = self._pending_done_item_id
        self._pending_done_question = None
        self._pending_done_item_id = None
        # 标记完成
        for s in self.dm.data["schedules"]:
            if s["id"] == item_id:
                s["completed"] = True
                self.dm.save()
                break
        self._enqueue(_completion_text(self.dm))

    def _done_no(self):
        title = self._pending_done_question
        item_id = self._pending_done_item_id
        self._pending_done_question = None
        self._pending_done_item_id = None
        # 延时1小时：更新时长和结束提醒
        for s in self.dm.data["schedules"]:
            if s["id"] == item_id:
                s["duration"] = s.get("duration", 30) + 60
                self.dm.save()
                # 注册新的结束提醒
                new_end = self._calc_end_time(s["start_time"], s["duration"])
                self._schedule_end_timers[item_id] = {
                    "title": s["title"],
                    "end_time": new_end,
                    "fired": False,
                }
                break
        self._enqueue(f"好的，「{title}」延时1小时，{new_end}我再提醒你~ ⏰")


    def _do_quit(self):
        try:
            self._win.close()
        except:
            pass
        try:
            self.root.destroy()
        except:
            pass

    # ─── GIF 加载 ──────────────────────────
    def _load_frames(self):
        global _current_img
        sz = self.SIZE
        for state, fname in [
            ("idle",     "idle.gif"),
            ("working",  "working.gif"),
            ("sleeping", "sleeping.gif"),
            ("thinking", "thinking.gif"),
            ("attention", "attention.gif"),
        ]:
            p = ASSET_DIR / fname
            if not p.exists():
                log(f"缺少 {fname}")
                continue
            frames, delays = [], []
            try:
                gif = Image.open(p)
                while True:
                    ns = _pil2ns(gif.copy().convert("RGBA"), sz, sz)
                    if ns:
                        frames.append(ns)
                        d = gif.info.get("duration", 120)
                        delays.append(max(60, d if d > 0 else 120))
                    gif.seek(gif.tell() + 1)
            except EOFError:
                pass
            except Exception as e:
                log(f"加载 {fname} 失败: {e}")
                continue
            if frames:
                self._frames[state] = (frames, delays)
                log(f"已加载 {state}: {len(frames)} 帧")
            else:
                log(f"{fname} 无有效帧")

        if "idle" in self._frames:
            _current_img = self._frames["idle"][0][0]
            try:
                self._content.setNeedsDisplay_(True)
            except:
                pass
        else:
            log("警告: idle.gif 加载失败，猫咪不可见")

    # ─── 动画 ──────────────────────────────
    def _start_anim(self):
        if self._anim_job:
            try:
                self.root.after_cancel(self._anim_job)
            except:
                pass
            self._anim_job = None
        self._frame_idx = 0
        self._tick_anim()

    def _tick_anim(self):
        global _current_img
        st = self._anim_state
        if st not in self._frames:
            st = next(iter(self._frames), None)
        if not st:
            return
        try:
            frames, delays = self._frames[st]
            n   = len(frames)
            idx = self._frame_idx % n
            ns  = frames[idx]
            if ns:
                _current_img = ns
                self._content.setNeedsDisplay_(True)
            self._frame_idx = (idx + 1) % n
            delay = delays[self._frame_idx % len(delays)]
            self._anim_job = self.root.after(delay, self._tick_anim)
        except Exception as e:
            log(f"_tick_anim: {e}")
            self._anim_job = self.root.after(200, self._tick_anim)

    def _set_state(self, state):
        if state not in self._frames:
            state = next(
                (s for s in ["idle", "working", "sleeping"] if s in self._frames),
                None)
        if not state or self._state == state:
            return
        log(f"状态: {self._state} → {state}")
        self._state      = state
        self._anim_state = state
        self._frame_idx  = 0

    # ─── 键盘监听（子进程隔离，避免 GIL 冲突）─
    def _start_pynput(self):
        def _reader(proc):
            """读取子进程输出，每行代表一次按键"""
            try:
                for line in iter(proc.stdout.readline, ''):
                    if line.strip():
                        now = time.time()
                        self._last_event_t  = now
                        self._last_activity = now
            except:
                pass
            if proc.poll() is None:
                log("⚠️ 键盘监听子进程退出，3s 后重启")
                time.sleep(3)
                self._start_pynput()

        # 子进程脚本：独立进程运行 pynput，避免与 tkinter GIL 冲突
        worker = '''
import sys, time
try:
    from pynput import keyboard
    def on_press(k):
        sys.stdout.write("k\\n")
        sys.stdout.flush()
    lst = keyboard.Listener(on_press=on_press)
    lst.daemon = True
    lst.start()
    lst.join()
except Exception as e:
    sys.stderr.write(f"pynput error: {e}\\n")
    sys.exit(1)
'''
        try:
            proc = subprocess.Popen(
                [sys.executable, "-c", worker],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                text=True, bufsize=1)
            log(f"✅ 键盘监听子进程启动 (pid={proc.pid})")
            threading.Thread(target=_reader, args=(proc,), daemon=True).start()
        except Exception as e:
            log(f"键盘监听子进程启动失败: {e}")

    def _flash_attention(self):
        """播放注意力动画，持续 3 秒后平滑过渡到常规动画"""
        if "attention" not in self._frames or self._state == "attention":
            return
        self._last_activity = time.time()
        self._last_event_t = time.time()
        self._attention_until = time.time() + 3
        self._state = "attention"
        self._anim_state = "attention"
        self._frame_idx = 0

    # ─── 状态更新 ──────────────────────────
    def _update_state(self):
        try:
            now = time.time()
            if now < self._attention_until:
                self.root.after(500, self._update_state)
                return
            idle_sec = now - self._last_activity
            if idle_sec >= self.SLEEP_TIMEOUT:
                self._screen_on = False
                self._set_state("sleeping")
            else:
                self._screen_on = True
                if now - self._last_event_t <= self.ACTIVE_TIMEOUT:
                    self._set_state("working")
                else:
                    self._set_state("idle")
            # 每5秒确保窗口在最前（解决全屏时消失问题）
            if int(now) % 5 == 0:
                try:
                    self._win.orderFrontRegardless()
                except:
                    pass
        except Exception as e:
            log(f"_update_state: {e}")
        self.root.after(500, self._update_state)

    # ─── 气泡队列 ──────────────────────────
    def _enqueue(self, text, do_speak=True):
        self._bubble_queue.append((text, do_speak))
        if not self._bubble_busy:
            self.root.after(0, self._next_bubble)

    def _next_bubble(self):
        if not self._bubble_queue:
            self._bubble_busy = False
            return
        self._bubble_busy = True
        text, do_speak = self._bubble_queue.pop(0)
        if do_speak:
            speak(text)
        self._bubble.show(
            text,
            on_done=lambda: self.root.after(500, self._next_bubble))

    # ─── 提醒循环（每 10s 检查一次）─
    def _reminder_loop(self):
        last_min = ""
        while True:
            try:
                now  = datetime.datetime.now()
                ts   = now.strftime("%H:%M")
                day  = str(now.date())
                if ts != last_min:
                    last_min = ts
                    events_to_fire = []

                    # 固定提醒
                    for t, msg in self.FIXED_REMINDERS:
                        key = f"f_{t}_{day}"
                        if ts == t and key not in self._fired_reminders:
                            self._fired_reminders.add(key)
                            events_to_fire.append(msg)

                    # 日程开始提醒
                    for item in self.dm.today_schedules():
                        if item["alerted"]:
                            continue
                        key = f"s_{item['id']}"
                        if ts == item["start_time"] and key not in self._fired_schedules:
                            self._fired_schedules.add(key)
                            self.dm.mark_alerted(item["id"])
                            _play_sfx("start")
                            msg = f"我们开始下一件行程吧！「{item['title']}」⏰"
                            events_to_fire.append(msg)
                            # 注册结束提醒
                            self._schedule_end_timers[item["id"]] = {
                                "title": item["title"],
                                "end_time": self._calc_end_time(item["start_time"], item["duration"]),
                                "fired": False,
                            }

                    # 日程结束提醒
                    for item_id, info in list(self._schedule_end_timers.items()):
                        if not info["fired"] and ts == info["end_time"]:
                            info["fired"] = True
                            title = info["title"]
                            msg = f"「{title}」时间到了！已经做完了吗？ 🤔"
                            events_to_fire.append(msg)
                            # 记录待回答的问题
                            self._pending_done_question = title
                            self._pending_done_item_id = item_id
                            # 延迟弹出选项（等气泡显示后）
                            self.root.after(3000, self._show_done_options)

                    # 统一播报：相同时间的事件排队，间隔 2 分钟
                    if events_to_fire:
                        self._fire_events_sequential(events_to_fire)

            except Exception as e:
                log(f"reminder_loop: {e}")
            time.sleep(10)

    def _calc_end_time(self, start_time, duration_min):
        """计算结束时间 HH:MM"""
        h, m = map(int, start_time.split(":"))
        total = h * 60 + m + duration_min
        return f"{total // 60:02d}:{total % 60:02d}"

    def _fire_events_sequential(self, events):
        """排队播报事件，间隔 2 分钟"""
        def _do():
            for i, msg in enumerate(events):
                if i > 0:
                    time.sleep(120)  # 间隔 2 分钟
                self.root.after(0, lambda m=msg: self._enqueue(m))
        threading.Thread(target=_do, daemon=True).start()

    # ─── 随机闲聊 ──────────────────────────
    def _random_chat_loop(self):
        while True:
            try:
                time.sleep(random.randint(1200, 2100))
                if (self._screen_on and
                        self._state == "idle"):
                    msg = random.choice(self.IDLE_QUOTES)
                    # 先闪烁思考动画
                    if "thinking" in self._frames:
                        self._attention_until = time.time() + 1.2
                        self._state = "thinking"
                        self._anim_state = "thinking"
                        self._frame_idx = 0
                        time.sleep(1.2)
                    self.root.after(0, lambda m=msg: self._enqueue(m, do_speak=False))
            except Exception as e:
                log(f"random_chat: {e}")
                time.sleep(60)

    # ─── TTS 预缓存（启动时预生成所有招呼/祝福语句，彻底消除首次卡顿）──
    def _precache_tts(self):
        try:
            voice = EDGE_VOICES.get(_voice_name, "zh-CN-YunxiNeural")
            rate_pct = int((_voice_rate - 240) / 240 * 100)
            rate_str = f"{rate_pct:+d}%"
            all_texts = (
                _GREETING_PRAISE + _GREETING_ENCOURAGE
                + _GREETING_BLESS + _GREETING_HAPPY
            )
            todo = [t for t in all_texts
                    if not _tts_cache_path(t, voice, rate_str).exists()]
            if not todo:
                log(f"TTS 缓存已就绪（{len(all_texts)} 条）")
                return
            log(f"开始预缓存 {len(todo)} 条 TTS（并发 4 条）")
            async def _precache_all():
                sem = asyncio.Semaphore(4)
                async def _gen(text):
                    async with sem:
                        cp = _tts_cache_path(text, voice, rate_str)
                        if not cp.exists():
                            tts = edge_tts.Communicate(
                                text, voice=voice, rate=rate_str)
                            await tts.save(str(cp))
                await asyncio.gather(*[_gen(t) for t in todo])
            asyncio.run(_precache_all())
            log(f"TTS 预缓存完成（{len(todo)} 条）")
        except Exception as e:
            log(f"TTS 预缓存异常: {e}")

    # ─── 自动同步（每天18:00触发）──
    def _auto_sync_loop(self):
        while True:
            try:
                now = datetime.datetime.now()
                if now.hour == 18 and now.minute == 0:
                    log("自动同步到备忘录")
                    sync_to_notes(self.dm)
                    time.sleep(61)
                time.sleep(30)
            except Exception as e:
                log(f"auto_sync: {e}")
                time.sleep(60)

    # ─── 早间问候 ──────────────────────────
    def _morning_greeting(self):
        if hasattr(self, '_greeting_done'):
            return
        self._greeting_done = True
        # 先播思考动画 3s，再播报问候
        if "thinking" in self._frames:
            self._attention_until = time.time() + 3.0
            self._state = "thinking"
            self._anim_state = "thinking"
            self._frame_idx = 0
        now = datetime.datetime.now()
        h   = now.hour
        greeting = ("早上好" if 5 <= h < 12 else
                    "中午好" if 12 <= h < 14 else
                    "下午好" if 14 <= h < 18 else
                    "晚上好" if 18 <= h < 22 else "你好")
        ds  = now.strftime("%Y年%m月%d日")
        wds = ["星期一","星期二","星期三","星期四","星期五","星期六","星期日"]
        wd  = wds[now.weekday()]

        def _do():
            try:
                weather = get_weather("深圳")
            except:
                weather = "天气未知"
            holiday = _get_holiday()
            holiday_text = f"，{holiday}快乐" if holiday else ""
            extra = ""
            if now.weekday() == 4:
                extra = "终于周五了，马上就可以休息了。"
            elif now.weekday() == 5:
                extra = "今天是周六，加班辛苦啦。"
            msg = f"{greeting}呀！今天是{ds}{wd}{holiday_text}。天气{weather}。{extra}主人要天天开心，你会越来越顺滴！"
            self.root.after(0, lambda: self._enqueue(msg))

        # 延迟 3s 让思考动画先播放
        def _delayed():
            if "thinking" in self._frames:
                time.sleep(3.0)
            _do()
        threading.Thread(target=_delayed, daemon=True).start()

    # ─── 开机自启 ──────────────────────────
    def _register_autostart(self):
        try:
            script    = str(Path(__file__).resolve())
            plist_dir = Path.home() / "Library/LaunchAgents"
            plist_dir.mkdir(parents=True, exist_ok=True)
            plist = plist_dir / "com.xiaotang.pet.plist"
            content = "\n".join([
                '<?xml version="1.0" encoding="UTF-8"?>',
                '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"',
                '  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">',
                '<plist version="1.0"><dict>',
                '  <key>Label</key><string>com.xiaotang.pet</string>',
                '  <key>ProgramArguments</key><array>',
                f'    <string>{sys.executable}</string>',
                f'    <string>{script}</string>',
                '  </array>',
                '  <key>RunAtLoad</key><true/>',
                '  <key>KeepAlive</key><false/>',
                f'  <key>StandardOutPath</key><string>{BASE_DIR}/stdout.log</string>',
                f'  <key>StandardErrorPath</key><string>{BASE_DIR}/stderr.log</string>',
                '</dict></plist>',
            ])
            if not plist.exists() or plist.read_text() != content:
                plist.write_text(content)
                log("开机自启已注册（下次登录生效）")
        except Exception as e:
            log(f"自启注册失败: {e}")

    _schedule_win = None  # 日程窗口单例

    def _open_schedule(self):
        _play_sfx("open")
        # 如果已有窗口打开，直接置顶
        if self._schedule_win:
            try:
                self._schedule_win.lift()
                self._schedule_win.focus_force()
            except:
                pass
            return
        def _create():
            win = ScheduleWindow(self.root, self.dm)
            self._schedule_win = win
            # 窗口关闭时清空引用
            win.bind("<Destroy>", lambda e: setattr(self, '_schedule_win', None))
        self.root.after(0, _create)

# ══════ 日程窗口 ══════
class ScheduleWindow(tk.Toplevel):
    def __init__(self, parent, dm):
        super().__init__(parent)
        self.dm = dm
        pet_name = self.dm.data.get("pet_name", "小唐")
        self.title(f"📅 {pet_name}的日程本")
        self.geometry("700x740")
        self.configure(bg="#FDF6EE")
        self.lift()
        self.focus_force()
        self._build()
        self._refresh()

    def _build(self):
        from tkinter import ttk, messagebox, filedialog
        self._ttk = ttk
        self._mb  = messagebox
        self._fd  = filedialog

        # 顶栏
        bar = tk.Frame(self, bg="#87CEEB", height=52)
        bar.pack(fill="x")
        bar.pack_propagate(False)
        pet_name = self.dm.data.get("pet_name", "小唐")

        def _change_pet_name():
            pop = tk.Toplevel(self)
            pop.title("修改名字")
            pop.geometry("250x100")
            pop.configure(bg="#FDF6EE")
            pop.transient(self)
            pop.grab_set()
            tk.Label(pop, text="新名字:", bg="#FDF6EE",
                     font=("PingFang SC", 12)).pack(pady=(10, 2))
            e = tk.Entry(pop, font=("PingFang SC", 12), width=12)
            e.insert(0, pet_name)
            e.pack()
            def _ok():
                name = e.get().strip()
                if name:
                    self.dm.data["pet_name"] = name
                    self.dm.save()
                    # 更新标题
                    self.title(f"📅 {name}的日程本")
                    title_label.config(text=f"🐱 {name}的日程本")
                    pop.destroy()
            tk.Button(pop, text="确定", command=_ok,
                      bg="#87CEEB", fg="black", font=("PingFang SC", 11),
                      relief="flat").pack(pady=6)

        title_label = tk.Label(bar, text=f"🐱 {pet_name}的日程本", bg="#87CEEB", fg="black",
                 font=("PingFang SC", 15, "bold"), cursor="hand2")
        title_label.pack(side="left", padx=16, pady=14)
        title_label.bind("<Button-1>", lambda e: _change_pet_name())
        tk.Label(bar, text="✏️", bg="#87CEEB", fg="#555", cursor="hand2",
                 font=("PingFang SC", 10)).pack(side="left")
        # 同步到备忘录按钮
        def _sync_notes():
            if sync_to_notes(self.dm):
                _play_sfx("save")
                self._mb.showinfo("同步成功", "日程已同步到备忘录", parent=self)
            else:
                self._mb.showerror("同步失败", "请检查备忘录权限", parent=self)
        tk.Button(bar, text="📋 同步", command=_sync_notes,
                  bg="#87CEEB", fg="#444", font=("PingFang SC", 10),
                  relief="flat", cursor="arrow").pack(side="left", padx=4)
        today = datetime.date.today()
        wds   = ["星期一","星期二","星期三","星期四","星期五","星期六","星期日"]
        tk.Label(bar, text=f"{today}  {wds[today.weekday()]}",
                 bg="#87CEEB", fg="#333",
                 font=("PingFang SC", 12)).pack(side="right", padx=16)

        # Tab
        tab_f = tk.Frame(self, bg="#B0E0E6")
        tab_f.pack(fill="x")
        self._tab_btns = {}
        for label, val in [("📌 今日日程", "schedule"), ("📒 历史导出", "history")]:
            btn = tk.Button(tab_f, text=label,
                            command=lambda v=val: self._switch_tab(v),
                            font=("PingFang SC", 12, "bold"),
                            relief="flat", cursor="arrow", padx=18, pady=6,
                            bg="#87CEEB", fg="black",
                            activebackground="#6CB4D4", activeforeground="black")
            btn.pack(side="left")
            self._tab_btns[val] = btn

        self._f_sched = tk.Frame(self, bg="#FDF6EE")
        self._f_hist  = tk.Frame(self, bg="#FDF6EE")
        self._build_schedule(self._f_sched)
        self._build_history(self._f_hist)
        self._switch_tab("schedule")

    def _switch_tab(self, val):
        for v, btn in self._tab_btns.items():
            btn.config(bg="#87CEEB" if v == val else "#B0E0E6",
                       fg="black" if v == val else "#555")
        if val == "schedule":
            self._f_hist.pack_forget()
            self._f_sched.pack(fill="both", expand=True)
            self.update_idletasks()
            self._refresh()
        else:
            self._f_sched.pack_forget()
            self._f_hist.pack(fill="both", expand=True)
            self.update_idletasks()
            self._h_query()

    def _build_schedule(self, p):
        from tkinter import ttk
        # 添加区
        af = tk.LabelFrame(p, text=" ➕ 添加新日程 ", bg="#FDF6EE",
                           font=("PingFang SC", 11, "bold"), fg="#FF6B35",
                           padx=12, pady=8)
        af.pack(fill="x", padx=14, pady=8)

        r1 = tk.Frame(af, bg="#FDF6EE"); r1.pack(fill="x", pady=3)
        tk.Label(r1, text="事件名称：", bg="#FDF6EE",
                 font=("PingFang SC", 12)).pack(side="left")
        self.v_title = tk.StringVar()
        # 下拉选择框（可输入也可选择）
        title_values = [t["title"] for t in self.dm.data.get("templates", [])]
        self._title_combo = ttk.Combobox(r1, textvariable=self.v_title, width=18,
                                          font=("PingFang SC", 12), values=title_values)
        self._title_combo.pack(side="left", padx=(0, 6))
        for txt, cmd in [("📋 历史", self._pick_history),
                         ("⭐ 模板", self._pick_template),
                         ("✏️ 管理", self._manage_templates)]:
            tk.Button(r1, text=txt, command=cmd,
                      bg="#87CEEB", fg="black",
                      font=("PingFang SC", 11), relief="flat",
                      cursor="arrow", padx=5).pack(side="left", padx=2)

        r2 = tk.Frame(af, bg="#FDF6EE"); r2.pack(fill="x", pady=3)
        tk.Label(r2, text="开始时间：", bg="#FDF6EE",
                 font=("PingFang SC", 12)).pack(side="left")
        # 默认时间：当前时间的下一个整点或半点
        now = datetime.datetime.now()
        if now.minute <= 30:
            default_h, default_m = now.hour, 30
        else:
            default_h = (now.hour + 1) % 24
            default_m = 0
        # 小时下拉
        hours = [f"{h:02d}" for h in range(24)]
        self.v_hour = tk.StringVar(value=f"{default_h:02d}")
        ttk.Combobox(r2, textvariable=self.v_hour, values=hours,
                     width=3, state="readonly", font=("PingFang SC", 12)).pack(side="left")
        tk.Label(r2, text="时", bg="#FDF6EE", font=("PingFang SC", 12)).pack(side="left")
        # 分钟下拉
        minutes = [f"{m:02d}" for m in range(0, 60, 5)]
        self.v_min = tk.StringVar(value=f"{default_m:02d}")
        ttk.Combobox(r2, textvariable=self.v_min, values=minutes,
                     width=3, state="readonly", font=("PingFang SC", 12)).pack(side="left")
        tk.Label(r2, text="分", bg="#FDF6EE", font=("PingFang SC", 12)).pack(side="left", padx=(0, 10))
        tk.Label(r2, text="时长：", bg="#FDF6EE",
                 font=("PingFang SC", 12)).pack(side="left")
        # 时长下拉（5-120分钟）
        durations = [str(d) for d in range(5, 125, 5)]
        self.v_dur = tk.StringVar(value="60")
        ttk.Combobox(r2, textvariable=self.v_dur, values=durations,
                     width=4, state="readonly", font=("PingFang SC", 12)).pack(side="left")
        tk.Label(r2, text="分钟", bg="#FDF6EE", font=("PingFang SC", 12)).pack(side="left")

        tk.Button(af, text="  ✅ 添加  ", command=self._add,
                  bg="#87CEEB", fg="black",
                  font=("PingFang SC", 13, "bold"),
                  relief="flat", cursor="arrow").pack(pady=(8, 2))

        # 列表
        lf = tk.LabelFrame(p, text=" 📌 今日日程 ", bg="#FDF6EE",
                           font=("PingFang SC", 11, "bold"), fg="#FF6B35",
                           padx=8, pady=6)
        lf.pack(fill="both", expand=True, padx=14, pady=4)

        style = ttk.Style(self)
        style.configure("T.Treeview", font=("PingFang SC", 12),
                        rowheight=30, background="white",
                        foreground="#222", fieldbackground="white",
                        cursor="arrow")
        style.configure("T.Treeview.Heading",
                        font=("PingFang SC", 12, "bold"), foreground="#FF6B35",
                        cursor="arrow")
        style.map("T.Treeview",
                  background=[("selected", "#FF9A6C")],
                  foreground=[("selected", "white")])

        cols = ("完成", "时间", "事件", "时长", "状态")
        self.tree = ttk.Treeview(lf, columns=cols, show="headings",
                                 height=7, style="T.Treeview")
        for c, w in zip(cols, [50, 75, 280, 80, 55]):
            self.tree.heading(c, text=c)
            self.tree.column(c, width=w, anchor="center")
        sb = ttk.Scrollbar(lf, orient="vertical", command=self.tree.yview)
        self.tree.configure(yscrollcommand=sb.set)
        self.tree.pack(side="left", fill="both", expand=True)
        sb.pack(side="right", fill="y")
        self.tree.tag_configure("done", background="#E8F5E9", foreground="#2e7d32")
        self.tree.tag_configure("pend", background="#FFFFFF", foreground="#222")

        # 点击完成列切换状态
        self.tree.bind("<ButtonRelease-1>", self._on_tree_click)
        self.tree.bind("<Double-1>", self._on_tree_edit)

        # 笔记
        nf = tk.LabelFrame(p, text=" 📝 今日笔记 ", bg="#FDF6EE",
                           font=("PingFang SC", 11, "bold"), fg="#FF6B35",
                           padx=8, pady=4)
        nf.pack(fill="x", padx=14, pady=(0, 4))
        self.note_text = tk.Text(nf, height=3, font=("PingFang SC", 12),
                                  relief="flat", bg="white", fg="#222",
                                  insertbackground="#222", wrap="word")
        self.note_text.pack(fill="x")
        today_s = datetime.date.today().isoformat()
        self.note_text.insert("1.0", self.dm.get_note(today_s))
        self.note_text.bind("<KeyRelease>",
            lambda e: self.dm.set_note(
                today_s, self.note_text.get("1.0", "end-1c")))

        brow = tk.Frame(p, bg="#FDF6EE"); brow.pack(pady=(0, 10))
        tk.Button(brow, text="🗑 删除选中", command=self._delete,
                  bg="#87CEEB", fg="black",
                  font=("PingFang SC", 11), relief="flat",
                  cursor="arrow").pack(side="left", padx=8)
        tk.Button(brow, text="💾 保存并关闭", command=self._save_close,
                  bg="#87CEEB", fg="black",
                  font=("PingFang SC", 11, "bold"),
                  relief="flat", cursor="arrow").pack(side="left", padx=8)

    def _build_history(self, p):
        from tkinter import ttk
        df = tk.LabelFrame(p, text=" 📅 日期范围 ", bg="#FDF6EE",
                           font=("PingFang SC", 11, "bold"), fg="#FF6B35",
                           padx=12, pady=8)
        df.pack(fill="x", padx=14, pady=8)

        row = tk.Frame(df, bg="#FDF6EE"); row.pack(fill="x")
        for lbl, attr in [("从：", "hv_from"), ("到：", "hv_to")]:
            tk.Label(row, text=lbl, bg="#FDF6EE",
                     font=("PingFang SC", 12)).pack(side="left")
            v = tk.StringVar(value=datetime.date.today().isoformat())
            setattr(self, attr, v)
            tk.Entry(row, textvariable=v, width=13,
                     font=("PingFang SC", 12), bg="white",
                     fg="#222").pack(side="left", padx=(0, 12))
        tk.Button(row, text="🔍 查询", command=self._h_query,
                  bg="#87CEEB", fg="black",
                  font=("PingFang SC", 12), relief="flat",
                  cursor="arrow").pack(side="left")

        qrow = tk.Frame(df, bg="#FDF6EE"); qrow.pack(fill="x", pady=(6, 0))
        for lbl, d in [("今天", 0), ("近7天", 6), ("近30天", 29), ("本月", -1)]:
            tk.Button(qrow, text=lbl,
                      command=lambda x=d: self._h_quick(x),
                      bg="#87CEEB", fg="black",
                      font=("PingFang SC", 11), relief="flat",
                      cursor="arrow", padx=8).pack(side="left", padx=4)

        pf = tk.LabelFrame(p, text=" 📋 预览 ", bg="#FDF6EE",
                           font=("PingFang SC", 11, "bold"), fg="#FF6B35",
                           padx=8, pady=6)
        pf.pack(fill="both", expand=True, padx=14, pady=4)
        self.h_prev = tk.Text(pf, font=("Menlo", 12), bg="white",
                               fg="#222", relief="flat", wrap="word",
                               state="disabled")
        psb = ttk.Scrollbar(pf, orient="vertical", command=self.h_prev.yview)
        self.h_prev.configure(yscrollcommand=psb.set)
        self.h_prev.pack(side="left", fill="both", expand=True)
        psb.pack(side="right", fill="y")

        br = tk.Frame(p, bg="#FDF6EE"); br.pack(pady=(4, 12))
        for txt, cmd, bg, fg in [
            ("💾 导出 TXT",  lambda: self._h_export("txt"),  "#87CEEB", "black"),
            ("📊 导出 JSON", lambda: self._h_export("json"), "#B0E0E6", "black"),
            ("📥 导入 JSON", self._h_import, "#90EE90", "black"),
        ]:
            tk.Button(br, text=txt,
                      command=cmd,
                      bg=bg, fg=fg,
                      font=("PingFang SC", 13, "bold"),
                      relief="flat", cursor="arrow").pack(side="left", padx=10)

    def _add(self):
        title = self.v_title.get().strip()
        h = self.v_hour.get().strip()
        m = self.v_min.get().strip()
        dur = self.v_dur.get().strip()
        if not title:
            self._mb.showwarning("提示", "请输入事件名称！", parent=self); return
        try:
            di = int(dur)
            assert 5 <= di <= 120
        except:
            self._mb.showwarning("提示", "时长应为 5-120 分钟", parent=self); return
        start = f"{int(h):02d}:{int(m):02d}"
        self.dm.add_schedule(title, start, di)
        self.v_title.set("")
        # 自动设置下一个事件的开始时间 = 本次结束时间
        end_total = int(h) * 60 + int(m) + di
        next_h, next_m = divmod(end_total % 1440, 60)
        self.v_hour.set(f"{next_h:02d}")
        self.v_min.set(f"{next_m:02d}")
        _play_sfx("add")
        # 更新下拉列表
        self._title_combo["values"] = [t["title"] for t in self.dm.data.get("templates", [])]
        self._refresh()

    def _save_close(self):
        _play_sfx("save")
        self.dm.save()
        self.destroy()

    def _manage_templates(self):
        """管理模板：添加/删除"""
        pop = tk.Toplevel(self)
        pop.title("✏️ 管理模板")
        pop.geometry("400x500")
        pop.configure(bg="#FDF6EE")
        pop.transient(self)
        pop.grab_set()

        tk.Label(pop, text="模板列表（可添加/删除）", bg="#FDF6EE",
                 font=("PingFang SC", 12, "bold")).pack(pady=8)

        listbox = tk.Listbox(pop, font=("PingFang SC", 12), height=12,
                             bg="white", fg="#222", selectbackground="#87CEEB")
        listbox.pack(fill="both", expand=True, padx=14, pady=4)

        def _refresh_list():
            listbox.delete(0, tk.END)
            for t in self.dm.data.get("templates", []):
                listbox.insert(tk.END, f"{t['start_time']}  {t['title']}  ({t['duration']}分钟)")
        _refresh_list()

        # 添加区
        add_frame = tk.Frame(pop, bg="#FDF6EE")
        add_frame.pack(fill="x", padx=14, pady=4)
        tk.Label(add_frame, text="名称:", bg="#FDF6EE", font=("PingFang SC", 11)).pack(side="left")
        e_title = tk.Entry(add_frame, width=10, font=("PingFang Sc", 11))
        e_title.pack(side="left", padx=2)
        tk.Label(add_frame, text="时间:", bg="#FDF6EE", font=("PingFang SC", 11)).pack(side="left")
        e_time = tk.Entry(add_frame, width=5, font=("PingFang Sc", 11))
        e_time.pack(side="left", padx=2)
        tk.Label(add_frame, text="时长:", bg="#FDF6EE", font=("PingFang SC", 11)).pack(side="left")
        e_dur = tk.Entry(add_frame, width=4, font=("PingFang Sc", 11))
        e_dur.insert(0, "30")
        e_dur.pack(side="left", padx=2)

        def _add_template():
            t = e_title.get().strip()
            tm = e_time.get().strip()
            d = e_dur.get().strip()
            if not t or not tm:
                return
            try:
                di = int(d)
                assert 1 <= di <= 1440
            except:
                return
            self.dm.data.setdefault("templates", []).append(
                {"title": t, "start_time": tm, "duration": di})
            self.dm.save()
            e_title.delete(0, tk.END)
            e_time.delete(0, tk.END)
            _refresh_list()
            self._title_combo["values"] = [t["title"] for t in self.dm.data.get("templates", [])]

        tk.Button(add_frame, text="➕ 添加", command=_add_template,
                  bg="#87CEEB", fg="black", font=("PingFang SC", 10),
                  relief="flat", cursor="arrow").pack(side="left", padx=4)

        # 删除按钮
        def _del_template():
            sel = listbox.curselection()
            if not sel:
                return
            idx = sel[0]
            templates = self.dm.data.get("templates", [])
            if 0 <= idx < len(templates):
                templates.pop(idx)
                self.dm.save()
                _refresh_list()
                self._title_combo["values"] = [t["title"] for t in templates]

        tk.Button(pop, text="🗑 删除选中", command=_del_template,
                  bg="#FFB3A7", fg="black", font=("PingFang SC", 11),
                  relief="flat", cursor="arrow").pack(pady=4)

    def _calc_end_time(self, start_time, duration):
        h, m = map(int, start_time.split(":"))
        total = h * 60 + m + duration
        return f"{total // 60:02d}:{total % 60:02d}"

    def _refresh(self):
        for r in self.tree.get_children():
            self.tree.delete(r)
        now = datetime.datetime.now().strftime("%H:%M")
        for s in sorted(self.dm.today_schedules(), key=lambda x: x["start_time"]):
            completed = s.get("completed", False)
            check = "  ✅  " if completed else "  ─  "
            status = "✅" if completed else ("⏳" if s["start_time"] <= now else "🔔")
            tag = "done" if completed else "pend"
            self.tree.insert("", "end", iid=str(s["id"]),
                values=(check, s["start_time"], s["title"],
                        f"{s['duration']}分钟", status), tags=(tag,))

    def _on_tree_click(self, event):
        """点击完成列切换勾选状态"""
        region = self.tree.identify_region(event.x, event.y)
        if region != "cell":
            return
        col = self.tree.identify_column(event.x)
        if col != "#1":
            return
        iid = self.tree.identify_row(event.y)
        if not iid:
            return
        today = datetime.date.today().isoformat()
        for s in self.dm.data["schedules"]:
            if str(s["id"]) == iid:
                # 只有昨日及以前的事件不允许取消勾选
                if s.get("date", today) < today and s.get("completed", False):
                    return
                s["completed"] = not s.get("completed", False)
                self.dm.save()
                if s["completed"]:
                    _play_sfx("complete")
                    speak(_completion_text(self.dm))
                else:
                    _play_sfx("cancel")
                break
        self._refresh()

    def _on_tree_edit(self, event):
        """双击编辑事件"""
        region = self.tree.identify_region(event.x, event.y)
        if region != "cell":
            return
        iid = self.tree.identify_row(event.y)
        if not iid:
            return
        # 找到对应事件
        item = None
        for s in self.dm.data["schedules"]:
            if str(s["id"]) == iid:
                item = s
                break
        if not item:
            return

        # 编辑弹窗
        pop = tk.Toplevel(self)
        pop.title("✏️ 编辑事件")
        pop.geometry("300x200")
        pop.configure(bg="#FDF6EE")
        pop.transient(self)
        pop.grab_set()

        tk.Label(pop, text="事件名称：", bg="#FDF6EE",
                 font=("PingFang SC", 11)).pack(anchor="w", padx=14, pady=(10, 2))
        e_title = tk.Entry(pop, font=("PingFang SC", 11), width=20)
        e_title.insert(0, item["title"])
        e_title.pack(padx=14)

        row = tk.Frame(pop, bg="#FDF6EE")
        row.pack(fill="x", padx=14, pady=4)
        tk.Label(row, text="时间：", bg="#FDF6EE",
                 font=("PingFang SC", 11)).pack(side="left")
        h, m = item["start_time"].split(":")
        e_h = ttk.Combobox(row, values=[f"{x:02d}" for x in range(24)],
                            width=3, state="readonly", font=("PingFang SC", 11))
        e_h.set(h)
        e_h.pack(side="left")
        tk.Label(row, text="时", bg="#FDF6EE", font=("PingFang SC", 11)).pack(side="left")
        e_m = ttk.Combobox(row, values=[f"{x:02d}" for x in range(0, 60, 5)],
                            width=3, state="readonly", font=("PingFang SC", 11))
        e_m.set(m)
        e_m.pack(side="left")
        tk.Label(row, text="分", bg="#FDF6EE", font=("PingFang SC", 11)).pack(side="left")

        row2 = tk.Frame(pop, bg="#FDF6EE")
        row2.pack(fill="x", padx=14, pady=4)
        tk.Label(row2, text="时长：", bg="#FDF6EE",
                 font=("PingFang SC", 11)).pack(side="left")
        e_dur = ttk.Combobox(row2, values=[str(d) for d in range(5, 125, 5)],
                              width=4, state="readonly", font=("PingFang SC", 11))
        e_dur.set(str(item.get("duration", 60)))
        e_dur.pack(side="left")
        tk.Label(row2, text="分钟", bg="#FDF6EE", font=("PingFang SC", 11)).pack(side="left")

        def _save():
            item["title"] = e_title.get().strip() or item["title"]
            item["start_time"] = f"{int(e_h.get()):02d}:{int(e_m.get()):02d}"
            item["duration"] = int(e_dur.get())
            self.dm.save()
            self._refresh()
            pop.destroy()

        tk.Button(pop, text="✅ 保存", command=_save,
                  bg="#87CEEB", fg="black", font=("PingFang SC", 11),
                  relief="flat").pack(pady=8)

    def _delete(self):
        for iid in self.tree.selection():
            self.dm.data["schedules"] = [
                s for s in self.dm.data["schedules"] if str(s["id"]) != iid]
        self.dm.save()
        self._refresh()

    def _pick_history(self):
        hist = self.dm.data["history"][-40:]
        if not hist:
            self._mb.showinfo("提示", "暂无历史记录", parent=self); return
        self._pick_popup("📋 历史记录",
            [(f"{h['start_time']}  {h['title']}  ({h['duration']}分钟)", h)
             for h in reversed(hist)])

    def _pick_template(self):
        items = []
        for t in self.dm.data["templates"]:
            if isinstance(t, dict):
                items.append(
                    (f"{t['start_time']}  {t['title']}  ({t['duration']}分钟)", t))
            else:
                items.append(
                    (str(t), {"title": str(t), "start_time": "09:00", "duration": 30}))
        if not items:
            self._mb.showinfo("提示", "暂无模板", parent=self); return
        self._pick_popup("⭐ 常用模板", items)

    def _pick_popup(self, title, items):
        pop = tk.Toplevel(self)
        pop.title(title)
        pop.geometry("460x380")
        pop.configure(bg="#FDF6EE")
        pop.lift()
        pop.focus_force()

        tk.Label(pop, text=title, bg="#FDF6EE", fg="#FF6B35",
                 font=("PingFang SC", 13, "bold")).pack(pady=10)

        frame = tk.Frame(pop, bg="white", bd=1, relief="solid")
        frame.pack(fill="both", expand=True, padx=12, pady=4)
        sb = tk.Scrollbar(frame); sb.pack(side="right", fill="y")
        lb = tk.Listbox(frame, font=("PingFang SC", 12),
                        bg="white", fg="#222",
                        selectbackground="#FF9A6C", selectforeground="white",
                        activestyle="none", relief="flat", bd=0,
                        yscrollcommand=sb.set)
        lb.pack(side="left", fill="both", expand=True)
        sb.config(command=lb.yview)

        dmap = {}
        for label, item in items:
            lb.insert("end", "  " + label)
            dmap[label.strip()] = item

        def pick():
            sel = lb.curselection()
            if not sel: return
            item = dmap.get(lb.get(sel[0]).strip(), {})
            self.v_title.set(item.get("title", ""))
            self.v_time.set(item.get("start_time", "09:00"))
            self.v_dur.set(str(item.get("duration", 30)))
            pop.destroy()
            self._switch_tab("schedule")

        tk.Button(pop, text="✅ 引用此项", command=pick,
                  bg="#87CEEB", fg="black",
                  font=("PingFang SC", 12, "bold"),
                  relief="flat", cursor="arrow").pack(pady=8)

    def _h_quick(self, days):
        today = datetime.date.today()
        d0 = (today.replace(day=1) if days == -1
              else today - datetime.timedelta(days=days))
        self.hv_from.set(d0.isoformat())
        self.hv_to.set(today.isoformat())
        self._h_query()

    def _h_query(self):
        d0, d1 = self.hv_from.get().strip(), self.hv_to.get().strip()
        try:
            datetime.date.fromisoformat(d0)
            datetime.date.fromisoformat(d1)
        except:
            self._mb.showwarning("格式错误", "日期格式：YYYY-MM-DD", parent=self)
            return
        text = self.dm.export_range(d0, d1)
        self.h_prev.configure(state="normal")
        self.h_prev.delete("1.0", "end")
        self.h_prev.insert("1.0", text)
        self.h_prev.configure(state="disabled")

    def _h_export(self, fmt):
        pet_name = self.dm.data.get("pet_name", "小唐")
        d0, d1 = self.hv_from.get().strip(), self.hv_to.get().strip()
        if fmt == "txt":
            fp = self._fd.asksaveasfilename(
                defaultextension=".txt",
                filetypes=[("文本", "*.txt")],
                initialfile=f"{pet_name}日程_{d0}_{d1}.txt",
                parent=self)
            if fp:
                _play_sfx("save")
                Path(fp).write_text(
                    self.dm.export_range(d0, d1), encoding="utf-8")
                self._mb.showinfo("✅ 导出成功", f"已保存：\n{fp}", parent=self)
        else:
            fp = self._fd.asksaveasfilename(
                defaultextension=".json",
                filetypes=[("JSON", "*.json")],
                initialfile=f"{pet_name}日程_{d0}_{d1}.json",
                parent=self)
            if fp:
                _play_sfx("save")
                data = self.dm.schedules_in_range(d0, d1)
                for s in data:
                    s["note"] = self.dm.get_note(s["date"])
                Path(fp).write_text(
                    json.dumps(data, ensure_ascii=False, indent=2),
                    encoding="utf-8")
                self._mb.showinfo("✅ 导出成功", f"已保存：\n{fp}", parent=self)

    def _h_import(self):
        """导入JSON数据"""
        fp = self._fd.askopenfilename(
            filetypes=[("JSON", "*.json")],
            title="选择要导入的JSON文件",
            parent=self)
        if not fp:
            return
        ok, msg = self.dm.import_data(fp)
        if ok:
            _play_sfx("add")
            self._mb.showinfo("✅ 导入成功", msg, parent=self)
            self._refresh()
            self._title_combo["values"] = [t["title"] for t in self.dm.data.get("templates", [])]
        else:
            self._mb.showerror("导入失败", msg, parent=self)

# ══════ 入口 ══════
if __name__ == "__main__":
    try:
        XiaoTang()
    except Exception as e:
        log(f"致命错误: {e}")
        import traceback
        log(traceback.format_exc())
        sys.exit(1)
