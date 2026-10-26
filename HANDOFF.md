# 桌面清单项目交接

> 最后更新：2026-10-26 14:45 CST
> 交接状态：1.6.1 build 18 已安装并推送；v1.6.1 标签已建立；GitHub Release 附件、图形界面与真实 EventKit 验证待完成

## 仓库定位

- 代码仓库：`CaiQingsong8/Personal`
- 分支：`codex/deskflow-calendar-sync`
- 功能提交：`47f546a`
- 交接提交 / 当前远端分支 SHA：`a638d2fa7c06d7ed7fcc1a98d39db306ba8719e4`
- 标签：`v1.6.1`（已推送）
- 项目目录：`DeskFlow-dev/桌面清单`
- 版本：1.6.1（build 18），最低 macOS 13.0，Universal 2
- 详细交接：[`桌面清单/HANDOFF.md`](桌面清单/HANDOFF.md)

## 已完成

- 任务与事项拥有分开的创建入口和存储/同步路径；本地任务不写入 Mac 日历或 Mac 事项。
- 月历底部改为“任务、事项、专注”三个显示控制。节假日和节气常显；任务控制本地任务与普通 Mac 日历日程，事项只控制事项图层。
- 后续新任务从同一天最近一条有具体时间的任务结束时刻接续，第一条仍按整点/半点排期，默认 2 小时。
- 日历与事项授权状态在应用激活时刷新；只读目标可导入，写回仅对可编辑目标启用。
- 1.6.1 / build 18 已构建并安装在 `/Applications/桌面清单.app`，未触碰用户数据目录。
- 日历语义测试、自测、macOS 13 Universal 2 构建、签名与 ZIP 校验通过。

## 未完成与限制

- GitHub `main` 与功能分支已推送至 `a638d2f`，远端核对通过；`v1.6.1` 标签已推送，`v1.6.0` 历史标签保留。
- GitHub Release 和 ZIP 附件仍未创建。当前主机的 GitHub CLI 凭据无效，Chrome 发布页自动化连续超时；这不代表用户网页会话未登录。
- 提升权限启动命令返回成功，但当前环境的 System Events 复查返回 `-10827`；尚不能确认 GUI 窗口已显示并可交互。
- 用户 iCloud/EventKit 真实同步与配偶 macOS 13 电脑实测待完成。

## 下一步

1. 使用可用的 GitHub Release 会话上传 `DeskFlow-1.6.1-macOS13-Universal.zip`，核对资产和发布页。
2. 在用户图形会话确认应用窗口、授权状态与同步列表。
3. 在真实 iCloud/EventKit 账户与 macOS 13 电脑验证互传和只读列表行为。

## 重要约束

- 保留既有 Git 时间线与 `v1.6.0` 标签；不覆盖远端历史。
- 真实数据位于 `~/Library/Application Support/DeskFlow`，升级时不得删除。
- 日历日程与事项保持独立模型、同步服务、标识与删除队列。
