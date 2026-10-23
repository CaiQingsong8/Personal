# 桌面清单项目交接

> 最后更新：2026-10-23
> 交接状态：1.6.0 build 17 已实现、验证并推送到 GitHub main；GitHub Release 附件尚未上传，真实 EventKit 账户验证待完成

## 仓库定位

- 仓库：`CaiQingsong8/Personal`
- 分支：`codex/deskflow-calendar-sync`
- 功能提交：`64fc9a9`（`feat: separate checklist calendar and reminder data`）
- 项目目录：`DeskFlow-dev/桌面清单`
- 当前版本：1.6.0（build 17），最低 macOS 13.0，Universal 2

## 已完成

- [x] 本地清单、Mac 日历日程、Mac 提醒事项拆为独立数据域；旧 JSON 在迁移时按旧标识拆分并保留双向关联记录、专注记录、计时器和删除重试队列。
- [x] 本地清单只在“今日 / 清单”管理；创建、编辑、完成和删除清单事项不会写入或删除 Mac 日历/提醒事项。
- [x] 月历保留节假日、节气常显；普通 Mac 日历日程作为独立图层，可单独显示/隐藏。
- [x] 日历同步只导入 Mac 日历日程；日程可在 DeskFlow 编辑并回写原日历事件，不从本地清单复制日程。
- [x] 今日增加“清单 / 提醒事项”两个内部分区；提醒事项页面与月历提醒事项图层独立控制。Mac 提醒事项仅与提醒事项数据互传，不会把日历日程或本地清单数据复制进去。
- [x] Mac 提醒事项无截止日期时以创建日期作为截止日期；用户自定义日期予以保留。
- [x] 月历、统计的主导航不变；兼容 macOS 13 的旧 EventKit 提醒事项授权 API，macOS 14+ 使用完整访问 API。
- [x] `Info.plist` 更新为 1.6.0 / build 17；Universal 2 应用已构建并安装到 `/Applications/桌面清单.app`。
- [x] 从当前工作树删除遗留的 1.4.1 安装包；原文件仍可从此前 Git 提交历史恢复。`/Applications` 中只找到最新版 `/Applications/桌面清单.app`。

## 验证状态

- [x] Calendar 语义与迁移测试通过（`CALENDAR_SEMANTICS_TESTS_OK`）：覆盖旧版仅清单、仅日历、仅提醒事项、双向关联记录迁移、删除队列保留及节日/节气显隐规则。
- [x] 隔离数据目录的 AppStore 自测通过（`SELF_TEST_OK`），没有访问真实用户数据目录。
- [x] macOS 15.4 SDK 下 x86_64 与 arm64 编译通过；最低部署目标为 macOS 13.0；应用签名验证通过。
- [x] 安装包版本核对为 1.6.0 / build 17。
- [ ] 真实 iCloud/EventKit 账户中的授权、日程回写、提醒事项双向更新与删除传播仍需在用户图形会话中验证。
- [ ] 未能从当前 Codex 进程启动已安装应用：LaunchServices 返回 `kLSNoExecutableErr`，直接启动崩溃报告显示 AppKit 在 `NSApplication.sharedApplication` 注册阶段终止，尚未进入 DeskFlow 应用代码。此状态不代表桌面 GUI 登录用户实际启动失败。
- [ ] 尚未在收件人 macOS 13 电脑上实测安装和授权。

## 仓库与发行

- 上一正式发行：`v1.5.0`，提交 `1aef76c915bc1b68aac4e9d8b3d3682915e89e8b`，发布页 <https://github.com/CaiQingsong8/Personal/releases/tag/v1.5.0>。
- `v1.6.0` 标注标签目标：`78b4beb80f487575d7222cdac17a9edd8684f458`；该提交已快进推送到 `main` 和 `codex/deskflow-calendar-sync`，并在远端核对确认。
- 发布包：`DeskFlow-1.6.0-macOS13-Universal.zip`（生成于忽略的 `build/` 目录；ZIP 完整性、Universal 2 架构与签名已验证）。
- 发布包 SHA-256：`374b0c50ae564c3c12ab3c94076589368add2534bf0e23f96dfe3676a373834b`。
- GitHub Release 页面与附件未能创建：仓库 GitHub MCP 没有 Release 写入接口；已打开 GitHub 新建发布页，但当前 Chrome 自动化读取标签页持续超时，因此不能确认附件上传或 Release 创建成功。不要将标签误认为 Release。
- 保留既有 Git 提交和标签历史；不覆盖 `v1.5.0`。
- 当前工作树只保留 1.6.0 构建与安装包；旧版本安装包不留在工作树，历史内容仍在 Git 中。

## 注意事项

- 真实用户数据位于 `~/Library/Application Support/DeskFlow`，不得随版本清理。
- 迁移遇到无法解码的数据时必须保留原文件，不得写入空数据覆盖。
- 当前应用为 ad-hoc 签名；其他 Mac 首次打开可能需要通过系统安全提示允许。
- 全天日历事件结束时间按次日零点排他边界表达。
