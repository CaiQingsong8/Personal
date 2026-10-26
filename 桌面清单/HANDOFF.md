# 桌面清单项目交接

> 最后更新：2026-10-26 14:40 CST
> 交接状态：1.6.1 build 18 已构建并安装；本地功能提交待推送；图形界面与真实 EventKit 账户验证未完成

## 仓库定位

- 代码仓库：`CaiQingsong8/Personal`
- 代码分支：`codex/deskflow-calendar-sync`
- 本轮功能提交：`47f546a`（`feat: clarify task and calendar controls`，本地提交）
- GitHub `main` 与功能分支当前都在：`9f06281dfa1c94a58a76649c962ee5bb798d7e86`；GitHub API 比较结果为与本地提交前基线一致
- 项目目录：`DeskFlow-dev/桌面清单`
- 当前版本：1.6.1（build 18），最低 macOS 13.0，Universal 2

## 本轮完成

- [x] “今日”内容分成“任务”和“事项”两个入口，各有独立的新建输入和“添加”按钮；本地任务不会同步到 Mac 日历或 Mac 事项。
- [x] 新建同一天的任务时，第一项按当前整点/半点规则起排，后续任务从当日最近一项有具体时间的任务结束时刻继续；默认时长仍为 2 小时。
- [x] 月历底部按“任务、事项、专注”显示三个控制。任务开关控制本地任务与普通 Mac 日历日程；节假日和节气始终显示。事项开关只控制事项图层。
- [x] 保留互相独立的日历日程和 Mac 事项同步面板。Mac 日历日程从 Mac 导入、在 DeskFlow 修改后回写原事件；Mac 事项仅与本地事项数据互传。
- [x] 授权状态在应用重新激活时刷新；分别呈现未连接、已授权、已连接、只读状态。可读取的只读日历/事项列表允许导入，写回操作只对可编辑目标开放。
- [x] 保持 macOS 13 的 EventKit 授权分支，macOS 14 及以上使用完整访问 API。
- [x] 1.6.1 / build 18 已安装到 `/Applications/桌面清单.app`，覆盖旧应用包；没有触碰 `~/Library/Application Support/DeskFlow`。
- [x] 1.6.1 Universal ZIP：`build/DeskFlow-1.6.1-macOS13-Universal.zip`；SHA-256：`f1ecd1f9f723aebabf810aa134388a6ff4b3ff73ce8cc2915b9f893827a48f42`。本地 1.6.0 ZIP 已移除。

## 验证状态

- [x] `CalendarSemanticsTests` 通过（`CALENDAR_SEMANTICS_TESTS_OK`），包含首个任务起排与后续任务接续时刻断言。
- [x] `SelfTest.swift` 在全新 `/private/tmp` 数据目录通过（`SELF_TEST_OK tasks=2 focusRecords=1`），验证新增第二个任务接续首项结束时刻；未访问真实数据目录。
- [x] `桌面清单/build.sh` 成功编译 x86_64 与 arm64；包内最低系统版本 13.0；`codesign --verify --deep --strict` 通过。
- [x] 已安装包核对为 1.6.1 / build 18，架构为 x86_64 + arm64。
- [x] ZIP 完整性检查通过。`iconutil` 报 `Invalid Iconset`，构建脚本使用已有 App 图标回退并成功签名。
- [ ] GUI 实际操作未确认：默认沙箱中的 `open -a` 返回 `kLSNoExecutableErr`；提升权限后 `open -a` 返回成功，但 System Events 二次查询仍报 `-10827`。尚无屏幕证据确认窗口显示并可操作。
- [ ] 未在用户的 iCloud/EventKit 账户上实测首次授权、日程写回、事项互传及删除传播。
- [ ] 未在配偶的 macOS 13 电脑上实机安装验证。

## Git 与发行

- 当前本地 `HEAD` 为功能提交 `47f546a`；待更新本 HANDOFF 与根 HANDOFF 后再提交文档。
- 本轮通过 GitHub API 确认 `main` 和 `codex/deskflow-calendar-sync` 仍停在 `9f06281`；`v1.6.1` 标签不存在，`v1.6.0` 标签仍指向 1.6.0。
- `git ls-remote` 对 GitHub HTTPS 请求返回 `Empty reply from server`；尚未推送。不要把此网络响应解释为账号未登录或权限不足。
- 1.6.1 GitHub Release 尚未创建；完成分支/主分支推送和标签后，另行验证发布页与 ZIP 附件。
- 保留既有 Git 提交与 `v1.6.0` 标签，不覆盖旧时间线。

## 注意事项

- 真实数据仅在 `~/Library/Application Support/DeskFlow`；升级、重装和清理构建产物均不得删除该目录。
- 日历日程和事项继续使用不同模型、标识、删除队列和同步服务；不得把本地任务复制进任一远端数据域。
- macOS 13 兼容路径为 `requestAccess(to:)`；新 API 必须保留 `#available(macOS 14.0, *)` 守卫。
