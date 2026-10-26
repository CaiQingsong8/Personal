# 桌面清单项目交接

> 最后更新：2026-10-26 16:29 CST
> 交接状态：1.6.2（build 19）已构建、安装至 `/Applications/桌面清单.app` 并启动；功能提交 `ba29855` 已创建，交接更新、远端推送与发行标签待完成。

## 仓库定位

- 代码仓库：`CaiQingsong8/Personal`
- 代码分支：`codex/deskflow-calendar-sync`
- 当前基线提交：`53746a6`（`docs: record DeskFlow app relaunch verification`）
- 本轮功能提交：`ba29855`（`feat: sync tasks independently with calendar and reminders`）
- 本轮交接提交：待提交
- 当前版本：1.6.2（build 19），最低 macOS 13.0，Universal 2
- 当前版本包：`build/DeskFlow-1.6.2-macOS13-Universal.zip`
- SHA-256：`1dd763b14ae2c1ef39b3ef9b5ef962376c18dd945b5c5988cef2d7b98d7d62ad`

## 1.6.2 本轮变更

- [x] “今日”页显示“今日内容”标题，并按截图将内容切换为“任务 / 事项”。
- [x] “今日 → 任务”加入 Mac 日历同步：用户选择可编辑日历后手动同步；按任务 UUID、EventKit 事件 ID 和外部 ID 更新原事件，避免重复新增；删除任务会进入独立任务删除队列，下次任务同步时从日历删除。
- [x] 任务使用独立事件标记，日历日程导入时排除这些任务事件，月历也不重复显示任务副本；从 Mac 导入的日程仍保存在 `calendarSchedules`，由原日程面板管理并回写。
- [x] 任务删除和日程删除在同一队列中用 `kind` 分开处理；旧版缺少 `kind` 的记录继续按日程删除处理。
- [x] Mac 提醒事项同步面板只保留在“今日 → 事项”，从月历底部移除重复面板。事项只与所选 Mac 提醒事项列表互传，不同步到 Mac 日历。
- [x] 提醒事项列表动态读取 EventKit 中的真实列表，显示列表颜色；按日历 ID 保持选择，重新授权、切换列表或系统列表变化后刷新。
- [x] 月历与统计视图保持原状；节日和节气继续常显，任务、事项和专注仍可独立显示/隐藏。
- [x] 更新 macOS 日历权限说明、README 和使用说明，明确任务到日历、事项到提醒事项、日程导入回写三条独立路径。

## 验证状态

- [x] `SelfTest.swift` 在全新 `/private/tmp/DeskFlow-SelfTest-data-final` 数据目录通过（`SELF_TEST_OK tasks=2 reminders=1 focusRecords=1`）；验证任务 EventKit ID 往返保存、任务删除队列分类为 `.task`、旧版删除记录无 `kind` 时仍可解码，且事项数据未混入任务的日历 ID。
- [x] `./build.sh` 成功构建 x86_64 与 arm64 Universal 应用。
- [x] 包内版本为 1.6.2 / build 19；`codesign --verify --deep --strict` 通过，架构为 x86_64 + arm64，编译目标最低 macOS 13.0。
- [x] ZIP 完整性检查通过。`iconutil` 报 `Invalid Iconset`，构建脚本回退使用已有图标并完成本地签名。
- [x] 旧版 `build/DeskFlow-1.6.1-macOS13-Universal.zip` 已删除；当前构建目录仅保留 1.6.2 ZIP。Git 历史和旧标签保留。
- [x] `/Applications/桌面清单.app` 已替换为 1.6.2 / build 19。2026-10-26 16:20 CST 通过 LaunchServices 启动；`lsof` 确认 PID 29323 的可执行文件来自 `/Applications/桌面清单.app/Contents/MacOS/DeskFlow`。
- [ ] 本会话没有屏幕采集能力，未取得窗口截图或真实点击证据。
- [ ] 未在用户 iCloud/EventKit 账户上实测任务写入、事项互传、日程回写及删除传播。
- [ ] 未在配偶的 macOS 13 电脑上实机安装验证。

## Git 与发行

- [x] 1.6.2 功能已在 `ba29855` 提交；交接文件需补充最终交接提交和远端核验结果。
- [ ] 推送 `codex/deskflow-calendar-sync`，并在确认远端仍位于已核验基线后将该快进历史推送到 `main`。
- [x] 本地 `main` 有独立提交并与 `origin/main` 分叉；未切换或覆盖本地 `main`。`origin/main` 是当前功能分支的祖先（本次提交前 `origin/main...HEAD` 为 `0 2`），因此只会把已验证功能分支历史快进推送到远端 `main`，不合并本地 `main` 的独立提交。
- [ ] `v1.6.2` 标签和 GitHub Release 尚未创建。
- [x] 保留 `v1.6.0`、`v1.6.1` 标签和对应 Git 时间线；不删除历史源码或提交。
- [x] 1.6.1 既有交付记录：标签 `v1.6.1` 已推送，旧 ZIP 当时 SHA-256 为 `f1ecd1f9f723aebabf810aa134388a6ff4b3ff73ce8cc2915b9f893827a48f42`；GitHub Release 与附件当时尚未完成。该版本记录保留在 Git 历史，旧 ZIP 已从本地构建目录清理。
- [x] 1.6.1 功能提交历史保留：`47f546a`（`feat: clarify task and calendar controls`）、`a638d2f`（`docs: record DeskFlow 1.6.1 handoff`）；后续远端核验提交曾为 `99c3d17`。本轮不覆盖这些提交或标签。

## 注意事项

- 真实数据仅位于 `~/Library/Application Support/DeskFlow`；升级、重装和清理构建产物均不得删除该目录。
- 三类内容保持明确边界：Mac 日历日程导入后修改并回写；本地任务由用户主动推送到 Mac 日历；事项与 Mac 提醒事项列表双向同步。任务与事项不得互传，也不得复制成彼此的事件。
- macOS 13 兼容路径为 `requestAccess(to:)`；新 API 必须使用 `#available(macOS 14.0, *)` 守卫。
