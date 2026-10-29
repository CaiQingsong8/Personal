# 桌面清单项目交接

## 2026-10-29：Personal 多项目发布整理

- 修正：用户指出新旧 Tag 重复。已删除刚创建的 19 个编号别名，保留原有 Tag 和 Release 链接；新版本只创建一个带项目编号的 Tag。此前修改 Release 标题后，5 个小唐旧 Tag 远端指向与本地原始标签不一致；已按本地原始标签恢复这 5 个远端引用。项目首页已移除失效别名链接。
- 用户要求小唐编号 01、桌面清单编号 02，后续项目从 03 编号；现存 Map 项目列为 03。
- GitHub 已有 Release 标题按项目编号命名；原 Release 的 Tag 和安装包链接保留。
- 根目录 README 提供项目导航、按项目名称搜索的发布页，以及当前 6.3.0 / 1.6.4 安装包直链。每次发新版须更新直链并沿用项目编号；GitHub 原生 Release/Tag 页无法按项目编号强制排序，也只有一个仓库级 Latest。草稿保留。
- `/Users/apple/Aohua/Personal` 原 checkout 在本次检查时有未提交更改且与远端分叉；不在该目录拉取、覆盖或提交。本次从干净的 DeskFlow-dev checkout 操作。

> 最后更新：2026-10-26 15:12 CST
> 交接状态：1.6.1 build 18 已安装并启动；v1.6.1 标签已推送；GitHub Release 附件、窗口交互与真实 EventKit 验证待完成

## 仓库定位

- 代码仓库：`CaiQingsong8/Personal`
- 分支：`codex/deskflow-calendar-sync`
- 功能提交：`47f546a`
- 交接提交：`a638d2f`
- 推送后远端核对提交：`99c3d17`
- 标签：`v1.6.1`（已推送）
- 项目目录：`DeskFlow-dev/桌面清单`
- 版本：1.6.1（build 18），最低 macOS 13.0，Universal 2
- 详细交接：[`桌面清单/HANDOFF.md`](桌面清单/HANDOFF.md)

## 已完成

- 任务与事项拥有分开的创建入口和存储/同步路径；本地任务不写入 Mac 日历或 Mac 事项。
- 月历底部改为“任务、事项、专注”三个显示控制。节假日和节气常显；任务控制本地任务与普通 Mac 日历日程，事项只控制事项图层。
- 后续新任务从同一天最近一条有具体时间的任务结束时刻接续，第一条仍按整点/半点排期，默认 2 小时。
- 日历与事项授权状态在应用激活时刷新；只读目标可导入，写回仅对可编辑目标启用。
- 1.6.1 / build 18 已构建、安装并请求启动 `/Applications/桌面清单.app`；LaunchServices 返回成功且系统服务列表存在 DeskFlow 进程。System Events 返回 `-10827`，窗口可见和交互仍未确认。未触碰用户数据目录。
- 日历语义测试、自测（`tasks=2 reminders=1 focusRecords=1`，确认事项创建独立）、macOS 13 Universal 2 构建、签名与 ZIP 校验通过。

## 未完成与限制

- GitHub `main` 与功能分支已推送并核对到 `99c3d17`；`v1.6.1` 标签已推送，`v1.6.0` 历史标签保留。
- GitHub Release 和 ZIP 附件仍未创建。当前主机的 GitHub CLI 凭据无效，Chrome 发布页自动化连续超时；这不代表用户网页会话未登录。
- System Events 复查返回 `-10827`；尚不能确认 GUI 窗口已显示并可交互。
- 用户 iCloud/EventKit 真实同步与配偶 macOS 13 电脑实测待完成。

## 下一步

1. 使用可用的 GitHub Release 会话上传 `DeskFlow-1.6.1-macOS13-Universal.zip`，核对资产和发布页。
2. 在用户图形会话确认应用窗口、授权状态与同步列表。
3. 在真实 iCloud/EventKit 账户与 macOS 13 电脑验证互传和只读列表行为。

## 重要约束

- 保留既有 Git 时间线与 `v1.6.0` 标签；不覆盖远端历史。
- 真实数据位于 `~/Library/Application Support/DeskFlow`，升级时不得删除。
- 日历日程与事项保持独立模型、同步服务、标识与删除队列。
