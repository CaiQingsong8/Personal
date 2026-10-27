# 桌面清单项目交接

## 2026-10-27：1.6.4 事项批量删除与重复显示修复

- “今日 → 事项”增加最近 30 天（含今天）的分日多选、全选及确认删除；已关联 Mac 事项写入独立待删除队列，在下次事项同步时按标识删除。任务和日历删除队列不受影响。
- 月历不再显示待删除的 Mac 事项，同一 DeskFlow UUID 的 Mac 副本只显示一次；EventKit 获取失败或删除匹配不唯一、未找到时保留待删除记录供重试。
- 同名同日但具有不同本地及 EventKit 标识的历史事项不能安全自动合并，需由用户辨认；未自动删除用户数据。
- 构建 macOS 13 目标 Universal 2 成功，签名及 plist 检查通过；独立临时数据的批量删除与持久化自测通过。已安装 `/Applications/桌面清单.app` 1.6.4 build 22 并确认进程启动。
- 尚未在真实 EventKit 账户执行事项删除和同步，也未验证 GUI 点击或 macOS 13 实机；待用户实测。没有匹配的待删除记录会持续显示为待重试。

> 最后更新：2026-10-26 17:10 CST
> 交接状态：1.6.3（build 21）已构建、安装至 `/Applications/桌面清单.app` 并启动；自测与静态检查通过。GitHub 的 `main` 与功能分支均已推送至 `e59b5a9`，`v1.6.3` 标签已验证指向该提交；GitHub Release 页面及 ZIP 附件仍未创建。

## 仓库定位

- 代码仓库：`CaiQingsong8/Personal`
- 代码分支：`codex/deskflow-calendar-sync`
- 当前基线提交：`7a4b536`（`docs: update DeskFlow 1.6.2 handoff`）
- 本轮功能提交：`6361ccb`（`fix: show local reminders and move calendar sync`）、`c3e51ac`（`fix: distinguish calendar schedule and task sync`）
- 本轮交接提交：本文件所在提交（以 `git log -1` 为准）；`v1.6.3` 发布标签指向 `e59b5a9`，该提交含 build 21 代码和交接记录。
- 当前版本：1.6.3（build 21），最低 macOS 13.0，Universal 2
- 当前版本包：`build/DeskFlow-1.6.3-macOS13-Universal.zip`
- SHA-256：`a16cc680ad17235daaefe9db2f102031a222b482f5533eb9e7a02fd93732c3f3`

## 1.6.3 修正

- [x] 月历“事项”图层合并本地事项与已授权后所选 Mac 提醒事项；本地事项即使没有 EventKit 权限也会显示。
- [x] 按 DeskFlow 事项 UUID、EventKit 事项标识和外部标识去重，同一条已同步事项优先显示本地 DeskFlow 记录。
- [x] 月历页移除日历同步面板；日程导入/回写和任务到日历同步集中在“今日 → 任务”，共享所选日历但仍是独立操作。
- [x] 提醒事项授权请求前激活应用；授权未返回时提供系统设置检查指引；未连接状态不再重复显示相同权限提示。
- [x] 保留 macOS 13 的 `requestAccess(to: .reminder)` 兼容分支；macOS 14+ 继续使用完整访问 API，并由 `#available` 守卫。
- [x] 明确两个日历操作的方向和对象：日程面板负责导入/回写 Mac 日程；任务面板负责把 DeskFlow 清单任务写入 Mac 日历。分别显示进行中和同步结果，避免任务状态覆盖日程状态。
- [x] 日程按钮命名为“回写日程”，任务面板命名为“Mac 日历清单任务同步”，按钮命名为“同步清单任务到日历”。

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

- [x] `SelfTest.swift` 在全新 `/private/tmp/DeskFlow-SelfTest-data-1.6.3-final` 数据目录通过（`SELF_TEST_OK tasks=2 reminders=1 focusRecords=1`）。
- [x] `./build.sh` 成功构建 macOS 13.0 目标的 x86_64 与 arm64 Universal 应用；`plutil -lint`、代码签名和架构检查通过。
- [x] 包内版本为 1.6.3 / build 21；Universal ZIP 完整性检查通过，SHA-256 已记录。
- [x] `iconutil` 报 `Invalid Iconset`，构建脚本回退使用已有图标并完成本地签名。
- [x] 旧版 `build/DeskFlow-1.6.2-macOS13-Universal.zip` 已删除；当前构建目录仅保留 1.6.3 ZIP。Git 历史和旧标签保留。
- [x] `/Applications/桌面清单.app` 已替换为 1.6.3 / build 21 并启动；安装后 `lsof` 确认可执行文件来自 `/Applications/桌面清单.app/Contents/MacOS/DeskFlow`。
- [ ] 未在用户 iCloud/EventKit 账户上实测授权弹窗、事项互传、日程回写及删除传播。
- [ ] 未在配偶的 macOS 13 电脑上实机安装验证；当前只完成 macOS 13 deployment target 编译。

## Git 与发行

- [x] 1.6.2 功能与交接已在 `ba29855`、`7a4b536` 提交；分支、远端 `main`、`v1.6.2` 标签已核验推送。
- [x] 1.6.3 已推送至 `codex/deskflow-calendar-sync` 与远端 `main`；两者均核验指向 `e59b5a9`。
- [x] 已创建并推送 `v1.6.3`，标签对象指向 `e59b5a9`。
- [ ] GitHub Release 页面和 Universal ZIP 附件尚未创建；需通过有写权限的 GitHub Releases UI/API 完成。
- [x] `v1.6.2` 标签已推送；截至本轮开始尚无 GitHub Release，保留其 Git 时间线。
- [x] 保留 `v1.6.0`、`v1.6.1` 标签和对应 Git 时间线；不删除历史源码或提交。
- [x] 1.6.1 既有交付记录：标签 `v1.6.1` 已推送，旧 ZIP 当时 SHA-256 为 `f1ecd1f9f723aebabf810aa134388a6ff4b3ff73ce8cc2915b9f893827a48f42`；GitHub Release 与附件当时尚未完成。该版本记录保留在 Git 历史，旧 ZIP 已从本地构建目录清理。
- [x] 1.6.1 功能提交历史保留：`47f546a`（`feat: clarify task and calendar controls`）、`a638d2f`（`docs: record DeskFlow 1.6.1 handoff`）；后续远端核验提交曾为 `99c3d17`。本轮不覆盖这些提交或标签。

## 注意事项

- 真实数据仅位于 `~/Library/Application Support/DeskFlow`；升级、重装和清理构建产物均不得删除该目录。
- 三类内容保持明确边界：Mac 日历日程导入后修改并回写；本地任务由用户主动推送到 Mac 日历；事项与 Mac 提醒事项列表双向同步。任务与事项不得互传，也不得复制成彼此的事件。
- 提醒事项授权：macOS 13 使用 `requestAccess(to: .reminder)`；macOS 14+ 使用完整访问 API，必须保持 `#available(macOS 14.0, *)` 守卫。真实授权仍须在目标 Mac 的系统弹窗/隐私设置验证。
