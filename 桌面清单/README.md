# 桌面清单

一个本地优先的 macOS 桌面效率工具：ToDo、番茄钟、月视图、时间统计，以及由用户主动触发的 Mac 日历互传。

主界面名称默认为“小唐日程”。名字可在右上角 `…` 中修改，例如输入“张三”后，主标题和专用日历都会使用“张三日程”。任务日期通过整块按钮弹出图形日历选择，避免误改年月；也可选择具体时间，定时任务默认 1 小时并以 30 分钟为步长调整。授权 Mac 日历后，月视图会显示系统日历中的节日与行程。

## 数据位置

`~/Library/Application Support/DeskFlow/data.json`

应用会在每次任务或计时变化后自动保存。右上角 `…` 可以导出完整 JSON 备份或 CSV 任务表。

## 构建

```bash
chmod +x build.sh
./build.sh
```

构建结果同时支持 Intel 和 Apple 芯片 Mac。要求 macOS 14 或更高版本，以及 Apple Command Line Tools。
