# 桌面清单项目交接

> 最后更新：2026-10-26 14:40 CST
> 交接状态：1.6.1 build 18 已安装；功能提交 `47f546a` 尚未推送；图形界面与真实 EventKit 账户验证待完成

## 仓库定位

- 代码仓库：`CaiQingsong8/Personal`
- 分支：`codex/deskflow-calendar-sync`
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

- 本地功能提交 `47f546a` 已创建；GitHub API 确认远端 `main` 与功能分支仍在 `9f06281`。本机 HTTPS `git ls-remote` 返回 `Empty reply from server`，尚未推送。
- `v1.6.1` 标签和 GitHub Release 尚未创建；`v1.6.0` 历史标签保留。
- 提升权限启动命令返回成功，但当前环境的 System Events 复查返回 `-10827`；尚不能确认 GUI 窗口已显示并可交互。
- 用户 iCloud/EventKit 真实同步与配偶 macOS 13 电脑实测待完成。

## 下一步

1. 更新并提交这两个 HANDOFF 文件，确认分支状态。
2. 通过可用 GitHub 路径推送 `47f546a` 及交接文档，核验 `main` 和功能分支远端 SHA。
3. 创建不覆盖既有历史的 `v1.6.1` 标签；验证 GitHub Release 页面及通用 ZIP 附件。
4. 在用户图形会话确认应用窗口、授权状态与同步列表。

## 重要约束

- 保留既有 Git 时间线与 `v1.6.0` 标签；不覆盖远端历史。
- 真实数据位于 `~/Library/Application Support/DeskFlow`，升级时不得删除。
- 日历日程与事项保持独立模型、同步服务、标识与删除队列。
