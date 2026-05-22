#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
小唐桌面宠物 v7.0
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
import threading, time, datetime, subprocess, sys, os, json, re, random
from pathlib import Path
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
        # NSWindowCollectionBehaviorFullScreenAuxiliary = 256
        behavior = 1 | 16 | 256
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
    """气泡背景视图（圆角 + 橙框）"""
    def drawRect_(self, rect):
        try:
            AppKit.NSColor.colorWithCalibratedRed_green_blue_alpha_(
                1.0, 0.97, 0.88, 0.97).setFill()
            path = AppKit.NSBezierPath.bezierPathWithRoundedRect_xRadius_yRadius_(
                AppKit.NSInsetRect(self.bounds(), 1, 1), 14, 14)
            path.fill()
            AppKit.NSColor.colorWithCalibratedRed_green_blue_alpha_(
                1.0, 0.55, 0.1, 1.0).setStroke()
            path.setLineWidth_(2.0)
            path.stroke()
        except:
            pass

class _CatWindow(AppKit.NSWindow):
    _drag_start_loc      = None
    _drag_start_origin   = None
    _drag_moved          = False
    _last_click_t        = 0
    _left_click_pending  = False
    _right_click_pending = False

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
            # 提取温度
            import re
            temp = re.search(r'[+-]?\d+°?[CcFf]?', text)
            temp_str = temp.group() if temp else ""
            return f"{chn} {temp_str}".strip()
    return text

# ══════ 语音 ══════
_say_proc = None  # 上一个 say 进程，用于避免重叠
_voice_name = "Meijia"
_voice_rate = 210
_voice_volume = 80

def speak(text):
    # 去除 emoji，保留中英文和标点
    clean = re.sub(
        r'[\U00010000-\U0010ffff\U00002702-\U000027B0'
        r'\U0001f000-\U0001faff\U00002600-\U000026ff]',
        '', text, flags=re.UNICODE).strip()
    if not clean:
        return
    # 添加停顿：在标点后加逗号，让语音更自然
    clean = re.sub(r'([。！？])', r'，', clean)
    # 非阻塞方式启动 say，避免线程 GIL 冲突
    global _say_proc
    try:
        if _say_proc and _say_proc.poll() is None:
            _say_proc.kill()
    except:
        pass
    try:
        _say_proc = subprocess.Popen(
            ["say", "-v", _voice_name, "-r", str(_voice_rate), clean],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except:
        pass

# ══════ 气泡（完全用 tkinter after 驱动）══════
class BubblePanel:
    def __init__(self, cat_win, tk_root):
        self._cat_win    = cat_win
        self._root       = tk_root
        self._panel      = None
        self._lbl        = None
        self._aid_type   = None   # typewrite after-id
        self._aid_close  = None   # close after-id
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

        BW, BH = 330, 105
        try:
            panel = AppKit.NSPanel.alloc().initWithContentRect_styleMask_backing_defer_(
                AppKit.NSMakeRect(0, 0, BW, BH),
                AppKit.NSWindowStyleMaskBorderless,
                AppKit.NSBackingStoreBuffered, False)
            panel.setOpaque_(False)
            panel.setBackgroundColor_(AppKit.NSColor.clearColor())
            panel.setHasShadow_(True)
            panel.setLevel_(AppKit.NSStatusWindowLevel + 2)
            panel.setIgnoresMouseEvents_(True)
            panel.setHidesOnDeactivate_(False)
            _safe_collection_behavior(panel)

            bg = _BubbleBGView.alloc().initWithFrame_(
                AppKit.NSMakeRect(0, 0, BW, BH))

            # 猫头 emoji
            icon = _ns_label("🐱")
            if icon:
                icon.setFont_(AppKit.NSFont.systemFontOfSize_(22))
                icon.setFrame_(AppKit.NSMakeRect(10, BH // 2 - 14, 34, 34))
                bg.addSubview_(icon)

            # 正文（兼容 pyobjc 8.x）
            lbl = _ns_label("")
            if lbl:
                try:
                    lbl.setTextColor_(
                        AppKit.NSColor.colorWithCalibratedRed_green_blue_alpha_(
                            0.15, 0.06, 0.0, 1.0))
                except:
                    pass
                try:
                    lbl.setFont_(AppKit.NSFont.boldSystemFontOfSize_(14))
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
                lbl.setFrame_(AppKit.NSMakeRect(50, 8, BW - 62, BH - 18))
                bg.addSubview_(lbl)

            panel.setContentView_(bg)

            # 定位：猫咪正上方
            try:
                cf  = self._cat_win.frame()
                bx  = cf.origin.x + cf.size.width / 2 - BW / 2
                by  = cf.origin.y + cf.size.height + 12
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

        # 无论气泡是否创建成功，都启动逐字 + 关闭定时
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
            delay = 75 if ch in "，。！？,.!?~～" else 40
            self._aid_type = self._root.after(delay, self._typewrite)
        else:
            wait = max(3000, min(len(self._full_txt) * 55 + 1500, 7000))
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
            try:
                cb()
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

class DataManager:
    def __init__(self):
        self.data = {
            "schedules": [], "history": [], "notes": {},
            "templates": [t.copy() for t in DEFAULT_TEMPLATES],
            "event_counts": {},
            "voice": {"name": "Meijia", "rate": 210, "volume": 80},
            "pet_name": "小唐",
        }
        self._load()
        # 强制重置模板为最新默认值
        self.data["templates"] = [t.copy() for t in DEFAULT_TEMPLATES]
        # 确保语音设置存在
        if "voice" not in self.data:
            self.data["voice"] = {"name": "Meijia", "rate": 210, "volume": 80}
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
        _voice_name = v.get("name", "Meijia")
        _voice_rate = v.get("rate", 210)
        _voice_volume = v.get("volume", 80)

    def set_voice(self, name, rate, volume=None):
        v = {"name": name, "rate": rate}
        if volume is not None:
            v["volume"] = volume
        else:
            v["volume"] = self.data.get("voice", {}).get("volume", 80)
        self.data["voice"] = v
        self.save()
        self._sync_voice()

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

# ══════ 主程序 ══════
class XiaoTang:
    SIZE = 192
    FIXED_REMINDERS = [
        ("10:00", "主人，记得喝水休息一下哦~ 💧"),
        ("12:00", "下班休息喽！记得吃午餐哟！🍱"),
        ("13:55", "快起床清醒一下，下午又是元气满满的开始！"),
        ("15:30", "记得喝水休息，站起来活动活动~ 🧘"),
        ("17:00", "可以放松一下了，顺便做做今日总结吧！📝"),
        ("18:00", "又是完美的一天，收工回家喽！🎉"),
    ]
    IDLE_QUOTES = [
        "主人在认真工作呢~ 🌟",
        "有什么需要帮忙的吗？",
        "今天辛苦啦，多喝水哦！",
        "我最喜欢主人了 💕",
        "要不要休息一下眼睛呀？",
        "加油加油！主人最棒了！✨",
        "时间过得好快，注意休息哟~",
    ]
    def __init__(self):
        log("=== 小唐 v7.0 启动 ===")

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

            win = _CatWindow.alloc().initWithContentRect_styleMask_backing_defer_(
                AppKit.NSMakeRect(wx, wy, sz, sz),
                AppKit.NSWindowStyleMaskBorderless,
                AppKit.NSBackingStoreBuffered, False)
            win.setOpaque_(False)
            win.setBackgroundColor_(AppKit.NSColor.clearColor())
            win.setHasShadow_(False)
            win.setLevel_(AppKit.NSStatusWindowLevel + 1)
            win.setIgnoresMouseEvents_(False)
            win.setHidesOnDeactivate_(False)
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
                self._show_cat_menu()
        except Exception as e:
            log(f"_poll_clicks: {e}")
        self.root.after(100, self._poll_clicks)

    _cat_menu_win = None  # 当前菜单窗口

    _show_completed = False  # 是否展开已完成

    def _show_cat_menu(self):
        """左键点击小猫弹出菜单（紧靠小猫左侧）"""
        if self._cat_menu_win:
            try: self._cat_menu_win.destroy()
            except: pass
            self._cat_menu_win = None

        try:
            menu = tk.Toplevel(self.root)
            menu.overrideredirect(True)
            menu.configure(bg="#FFF5EB")
            menu.attributes("-topmost", True)
            self._cat_menu_win = menu

            bw = 280

            def _close_menu(e=None):
                try: menu.destroy()
                except: pass
                self._cat_menu_win = None

            # 问候区
            if self._pending_done_question:
                title = self._pending_done_question
                for text, cmd in [(f"✅ 做完了「{title}」", self._done_yes),
                                  ("⏰ 还没，再给1小时", self._done_no)]:
                    def _c(c=cmd):
                        _close_menu(); c()
                    btn = tk.Button(menu, text=text, command=_c,
                                    font=("PingFang SC", 13), relief="flat", anchor="w",
                                    padx=14, pady=5, bg="#FFF5EB", fg="#333",
                                    activebackground="#FFE0CC", cursor="arrow")
                    btn.pack(fill="x")
            else:
                def _greet():
                    now = datetime.datetime.now()
                    ds = now.strftime("%m月%d日")
                    wds = ["星期一","星期二","星期三","星期四","星期五","星期六","星期日"]
                    wd = wds[now.weekday()]
                    holiday = _get_holiday()
                    if holiday:
                        msg = f"主人你好呀！今天是{ds}{wd}，{holiday}快乐！🎊"
                    elif now.weekday() == 4:
                        msg = f"主人你好呀！今天是{ds}{wd}，终于周五啦！马上就可以休息了！🎉"
                    elif now.weekday() == 5:
                        msg = f"主人你好呀！今天是{ds}{wd}，主人加班辛苦了，下班就可以美美休息了呢~ 💪"
                    else:
                        msg = f"主人你好呀！今天是{ds}{wd}。"
                    self._enqueue(msg)
                btn = tk.Button(menu, text="💬 打招呼", cursor="arrow",
                                command=lambda: (_close_menu(), _greet()),
                                font=("PingFang SC", 13), relief="flat", anchor="w",
                                padx=14, pady=5, bg="#FFF5EB", fg="#333",
                                activebackground="#FFE0CC")
                btn.pack(fill="x")

            # 今日待办区
            tk.Frame(menu, bg="#DDD", height=1).pack(fill="x", padx=8)
            todo_frame = tk.Frame(menu, bg="#FFF5EB")
            todo_frame.pack(fill="x")

            def _refresh_todos():
                for w in todo_frame.winfo_children():
                    w.destroy()
                items = self.dm.today_schedules()
                if not items:
                    return
                items_sorted = sorted(items, key=lambda x: x["start_time"])
                done_items = [i for i in items_sorted if i.get("completed")]
                pend_items = [i for i in items_sorted if not i.get("completed")]

                # 未完成
                for item in pend_items[:6]:
                    title = item["title"][:4]
                    label = f"⬜ {item['start_time']} {title}"
                    def _toggle(it=item):
                        it["completed"] = True
                        self.dm.save()
                        speak(f"主人真棒！「{it['title']}」完成啦！")
                        _refresh_todos()
                    b = tk.Button(todo_frame, text=label, command=_toggle,
                                  font=("PingFang SC", 12), relief="flat", anchor="w",
                                  padx=14, pady=3, bg="#FFF5EB", fg="#333",
                                  activebackground="#FFE0CC", cursor="arrow")
                    b.pack(fill="x")

                # 已完成折叠
                if done_items:
                    def _toggle_done():
                        self._show_completed = not self._show_completed
                        _refresh_todos()
                    arrow = "▼" if self._show_completed else "▶"
                    b = tk.Button(todo_frame, text=f"{arrow} 已完成 ({len(done_items)})",
                                  command=_toggle_done,
                                  font=("PingFang SC", 11), relief="flat", anchor="w",
                                  padx=14, pady=2, bg="#F5E6D0", fg="#888",
                                  activebackground="#FFE0CC", cursor="arrow")
                    b.pack(fill="x")
                    if self._show_completed:
                        for item in done_items:
                            title = item["title"][:4]
                            label = f"✅ {item['start_time']} {title}"
                            def _untoggle(it=item):
                                it["completed"] = False
                                self.dm.save()
                                _refresh_todos()
                            b = tk.Button(todo_frame, text=label, command=_untoggle,
                                          font=("PingFang SC", 12), relief="flat", anchor="w",
                                          padx=28, pady=3, bg="#FFF5EB", fg="#888",
                                          activebackground="#FFE0CC", cursor="arrow")
                            b.pack(fill="x")

            _refresh_todos()

            # 语音设置区（2行：人声一行，语速+音量一行）
            tk.Frame(menu, bg="#DDD", height=1).pack(fill="x", padx=8)

            # 第一行：人声
            v1 = tk.Frame(menu, bg="#FFF5EB")
            v1.pack(fill="x")
            voices = ["Meijia", "Ting-Ting", "Sandy", "Shelley", "Flo"]
            current_voice = self.dm.data.get("voice", {}).get("name", "Meijia")
            v_voice = tk.StringVar(value=current_voice)
            tk.Label(v1, text="人声", bg="#FFF5EB", fg="#555",
                     font=("PingFang SC", 10)).pack(side="left", padx=(14, 2))
            cb_voice = ttk.Combobox(v1, textvariable=v_voice, values=voices,
                                     width=12, state="readonly", font=("PingFang SC", 10))
            cb_voice.pack(side="left", padx=2)

            # 第二行：语速 + 音量
            v2 = tk.Frame(menu, bg="#FFF5EB")
            v2.pack(fill="x")
            speeds = {"慢": 150, "中": 210, "快": 280}
            current_rate = self.dm.data.get("voice", {}).get("rate", 210)
            speed_label = [k for k, v in speeds.items() if v == current_rate][0] if current_rate in speeds.values() else "中"
            v_speed = tk.StringVar(value=speed_label)
            tk.Label(v2, text="语速", bg="#FFF5EB", fg="#555",
                     font=("PingFang SC", 10)).pack(side="left", padx=(14, 2))
            cb_speed = ttk.Combobox(v2, textvariable=v_speed,
                                     values=list(speeds.keys()),
                                     width=3, state="readonly", font=("PingFang SC", 10))
            cb_speed.pack(side="left", padx=2)

            volumes = {"静音": 0, "低": 30, "中": 60, "高": 80, "最大": 100}
            current_vol = self.dm.data.get("voice", {}).get("volume", 80)
            vol_label = [k for k, v in volumes.items() if v == current_vol][0] if current_vol in volumes.values() else "高"
            v_vol = tk.StringVar(value=vol_label)
            tk.Label(v2, text="音量", bg="#FFF5EB", fg="#555",
                     font=("PingFang SC", 10)).pack(side="left", padx=(8, 2))
            cb_vol = ttk.Combobox(v2, textvariable=v_vol,
                                   values=list(volumes.keys()),
                                   width=3, state="readonly", font=("PingFang SC", 10))
            cb_vol.pack(side="left", padx=2)

            def _apply_voice():
                vn = v_voice.get()
                spd = speeds.get(v_speed.get(), 210)
                vol = volumes.get(v_vol.get(), 80)
                self.dm.set_voice(vn, spd, vol)
            cb_voice.bind("<<ComboboxSelected>>", lambda e: _apply_voice())
            cb_speed.bind("<<ComboboxSelected>>", lambda e: _apply_voice())
            cb_vol.bind("<<ComboboxSelected>>", lambda e: _apply_voice())

            tk.Frame(menu, bg="#DDD", height=1).pack(fill="x", padx=8)
            btn = tk.Button(menu, text="📅 打开日程本", cursor="arrow",
                            command=lambda: (_close_menu(), self._open_schedule()),
                            font=("PingFang SC", 13), relief="flat", anchor="w",
                            padx=14, pady=5, bg="#FFF5EB", fg="#333",
                            activebackground="#FFE0CC")
            btn.pack(fill="x")

            # 定位 + 跟随
            menu.update_idletasks()
            bh = menu.winfo_reqheight()

            def _reposition():
                if not self._cat_menu_win:
                    return
                try:
                    cf = self._win.frame()
                    scr = AppKit.NSScreen.mainScreen().frame()
                    cat_x = int(cf.origin.x)
                    cat_y_tk = int(scr.size.height - cf.origin.y - cf.size.height)
                    cat_cy = cat_y_tk + self.SIZE // 2
                    x = cat_x - bw - 6
                    y = cat_cy - bh // 2
                    if x < 8:
                        x = cat_x + self.SIZE + 6
                    menu.geometry(f"+{x}+{y}")
                except:
                    pass
                if self._cat_menu_win:
                    menu.after(200, _reposition)

            _reposition()

            # 点击外部关闭
            def _check_close():
                if not self._cat_menu_win:
                    return
                try:
                    mp = AppKit.NSEvent.mouseLocation()
                    scr = AppKit.NSScreen.mainScreen().frame()
                    mx_tk = int(mp.x)
                    my_tk = int(scr.size.height - mp.y)
                    gx = menu.winfo_rootx()
                    gy = menu.winfo_rooty()
                    gw = menu.winfo_width()
                    gh = menu.winfo_height()
                    if not (gx <= mx_tk <= gx + gw and gy <= my_tk <= gy + gh):
                        if AppKit.NSEvent.pressedMouseButtons() & 1:
                            _close_menu()
                            return
                except:
                    pass
                if self._cat_menu_win:
                    menu.after(150, _check_close)

            menu.after(300, _check_close)

        except Exception as e:
            log(f"菜单弹出失败: {e}")
            self._enqueue("喵~ 主人你好呀！")

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
        self._enqueue(f"主人真棒！「{title}」完成啦！🎉 继续加油！")

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

    # ─── 状态更新 ──────────────────────────
    def _update_state(self):
        try:
            now = time.time()
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
                            msg = f"主人，我们开始下一件行程吧！「{item['title']}」⏰"
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
                    self.root.after(0, lambda m=msg: self._enqueue(m, do_speak=False))
            except Exception as e:
                log(f"random_chat: {e}")
                time.sleep(60)

    # ─── 早间问候 ──────────────────────────
    def _morning_greeting(self):
        if hasattr(self, '_greeting_done'):
            return
        self._greeting_done = True
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
                weather = "🌤 天气未知"
            wd_idx = now.weekday()
            sentences = [f"{greeting}！今天是{ds}{wd}。"]
            # 节日问候
            holiday = _get_holiday()
            if holiday:
                sentences.append(f"今天是{holiday}，祝主人节日快乐！🎊")
            # 周五/周六特殊文案
            elif wd_idx == 4:  # 周五
                sentences.append("终于周五啦！马上就可以休息了！🎉")
            elif wd_idx == 5:  # 周六
                sentences.append("主人今天加班辛苦了，下班就可以美美休息了呢~ 💪")
            sentences.append(f"深圳今天{weather}")
            sentences.append("快告诉我今天的日程安排吧！")
            for s in sentences:
                self.root.after(0, lambda m=s: self._enqueue(m))
                time.sleep(0.2)
            self.root.after(len(sentences) * 5000, self._open_schedule)

        threading.Thread(target=_do, daemon=True).start()

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
            default_time = now.strftime("%H") + ":30"
        else:
            default_time = (now + datetime.timedelta(hours=1)).strftime("%H") + ":00"
        self.v_time = tk.StringVar(value=default_time)
        tk.Entry(r2, textvariable=self.v_time, width=7,
                 font=("PingFang SC", 12), bg="white", fg="#222").pack(side="left", padx=(0, 16))
        tk.Label(r2, text="持续(分钟)：", bg="#FDF6EE",
                 font=("PingFang SC", 12)).pack(side="left")
        self.v_dur = tk.StringVar(value="30")
        tk.Entry(r2, textvariable=self.v_dur, width=5,
                 font=("PingFang SC", 12), bg="white", fg="#222").pack(side="left")

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
        for txt, fmt, bg, fg in [
            ("💾 导出 TXT",  "txt",  "#87CEEB", "black"),
            ("📊 导出 JSON", "json", "#B0E0E6", "black"),
        ]:
            tk.Button(br, text=txt,
                      command=lambda f=fmt: self._h_export(f),
                      bg=bg, fg=fg,
                      font=("PingFang SC", 13, "bold"),
                      relief="flat", cursor="arrow").pack(side="left", padx=10)

    def _add(self):
        title = self.v_title.get().strip()
        start = self.v_time.get().strip()
        dur   = self.v_dur.get().strip()
        if not title:
            self._mb.showwarning("提示", "请输入事件名称！", parent=self); return
        if not re.match(r"^\d{1,2}:\d{2}$", start):
            self._mb.showwarning("提示", "时间格式：HH:MM（如 09:30）", parent=self); return
        try:
            di = int(dur)
            assert 1 <= di <= 1440
        except:
            self._mb.showwarning("提示", "时长应为 1-1440 分钟", parent=self); return
        h, m = start.split(":")
        self.dm.add_schedule(title, f"{int(h):02d}:{int(m):02d}", di)
        self.v_title.set("")
        # 更新下拉列表
        self._title_combo["values"] = [t["title"] for t in self.dm.data.get("templates", [])]
        self._refresh()

    def _save_close(self):
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
                    speak(f"主人真棒！「{s['title']}」完成啦！")
                break
        self._refresh()

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
        d0, d1 = self.hv_from.get().strip(), self.hv_to.get().strip()
        if fmt == "txt":
            fp = self._fd.asksaveasfilename(
                defaultextension=".txt",
                filetypes=[("文本", "*.txt")],
                initialfile=f"{pet_name}日程_{d0}_{d1}.txt",
                parent=self)
            if fp:
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
                data = self.dm.schedules_in_range(d0, d1)
                for s in data:
                    s["note"] = self.dm.get_note(s["date"])
                Path(fp).write_text(
                    json.dumps(data, ensure_ascii=False, indent=2),
                    encoding="utf-8")
                self._mb.showinfo("✅ 导出成功", f"已保存：\n{fp}", parent=self)

# ══════ 入口 ══════
if __name__ == "__main__":
    try:
        XiaoTang()
    except Exception as e:
        log(f"致命错误: {e}")
        import traceback
        log(traceback.format_exc())
        sys.exit(1)
