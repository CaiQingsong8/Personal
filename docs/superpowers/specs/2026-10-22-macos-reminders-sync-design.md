# macOS 提醒事项互传与月历显示设计

> 用户于 2026-10-22 确认本设计；当前等待规格审阅，尚未开始改动应用代码。

## 目标

- 在月历底部现有“任务 / Mac 日历 / 专注”图层开关后增加“提醒事项”开关，显示或隐藏 Mac 提醒事项。
- 提供清单任务与所选 Mac 提醒事项列表之间的手动双向同步。
- 使用稳定任务 ID 更新已有提醒事项，避免重复创建；从清单删除并同步时删除其关联的 Mac 提醒事项。
- 继续支持 macOS 13 Ventura，并兼容 macOS 14 及以上的 EventKit 授权变化。

## 界面

- 月历图层行新增第四个等宽按钮“提醒事项”，使用独立的 `@AppStorage` 显示开关，默认开启，与其他月历图层一致。
- 当前月格按提醒事项截止日期显示项目。完成项以弱化样式呈现，未完成项正常呈现；单日项目超过空间时用剩余数量汇总。
- 与 DeskFlow 任务关联的 Reminders 项由“任务”图层显示一次；“提醒事项”图层过滤关联副本，避免重复显示。
- 在月历页面增加独立的“Mac 提醒事项同步”面板，沿用日历面板的交互：选择可编辑的提醒事项列表、创建或选择 DeskFlow 专用列表、“导入提醒事项”和“同步到提醒事项”两个手动操作，以及连接状态、进度和结果摘要。
- 提醒事项服务和日历服务各自保留授权状态、所选列表和同步反馈，互不覆盖对方的连接信息。

## 同步与数据规则

### 字段映射

- 双向映射标题、备注、截止日期和完成状态。
- DeskFlow 的具体时间任务以本地日期和时分写入提醒事项截止时间；未指定具体时间的任务写入仅含年月日的截止日期，不合成次日结束时间。
- Mac 提醒事项有截止日期时按该日期导入；没有截止日期时，以 EventKit 创建日期作为清单截止日期并按日期项导入，不创建跨日时间段。如果 EventKit 未提供创建日期，则使用当前本地日期作为兜底。用户之后可在清单中自定义截止日期。
- 清单模型未表达的提醒事项字段（例如重复规则、优先级和提醒时间）不映射进清单。更新已有 Mac 项时只改映射字段和 DeskFlow 关联标记，不主动清空其他原生字段；新建提醒事项使用系统默认的非重复、无额外提醒设置。

### 身份与更新

- Reminders 使用独立的本地关联字段，不复用 `calendarEventIdentifier`、`calendarIdentifier` 或日历删除队列。
- 每个导入或导出的清单任务使用 `deskflow://reminder/<task UUID>` 关联标记；同时保存 `calendarItemIdentifier`、`calendarItemExternalIdentifier`、提醒事项列表标识和上次同步时间，供标记不可用时回退匹配。
- 新导入的 Mac 提醒事项生成清单 UUID 后，若其 URL 为空则写入 DeskFlow UUID 标记；已有其他 URL 时保留原值，并保存 EventKit 标识作为回退依据。导出时只有空 URL 或 DeskFlow 自己的 URL 才会写入/更新关联标记。
- 导入优先按 DeskFlow UUID 标记匹配，其次按已保存的 EventKit 标识；导出和删除会在所有提醒事项列表中查找关联对象。外部标识只有在候选对象唯一时才作为回退条件。唯一命中其他列表的关联对象时移动到所选列表；新建对象写入所选列表。标题和日期不作为身份键。
- 导入已关联项目时更新原清单任务；若同一个 UUID 或 EventKit 标识出现多个候选项，报告冲突并跳过，不新增第二项。
- Reminders 的列表选择独立于 Calendar 选择。月历显示和导入范围都限于当前选定列表。

### 删除与失败恢复

- 删除带 Reminders 关联信息的清单任务时，将其 Reminders 标识保存到单独的持久化待删除队列；下次执行任一 Reminders 同步操作时重试删除，只有删除成功或确认项目已不存在后才清除队列项。
- Mac 端直接删除提醒事项时不自动删除本地清单任务。若清单任务仍有旧关联标识，导出按日历现有保护策略报告“未安全匹配”并跳过，不悄悄新建重复项。
- 授权被拒、所选列表失效、标识多重匹配或 EventKit 写入失败时，显示具体状态；未完成的删除保留待重试，已完成的导入/同步结果先保存。
- 新增 Codable 字段均可选，旧版本 JSON 缺少提醒事项关联或删除队列字段时按空值/空数组解码，保持现有本地数据可读。

## macOS 兼容性

- 保持最低部署版本 macOS 13.0，并继续生成 x86_64 和 arm64 架构。
- macOS 13 使用 `requestAccess(to: .reminder)` 与旧授权状态；macOS 14 及以上按可用性检查调用 `requestFullAccessToReminders()` 并检查完整访问状态。
- `Info.plist` 同时提供 `NSRemindersUsageDescription` 和 `NSRemindersFullAccessUsageDescription`，覆盖 Ventura 与新版系统的权限说明。
- 使用现有部署目标和 SDK 可用的 SwiftUI/EventKit API；任何 macOS 14+ API 都需包在 `#available(macOS 14.0, *)` 分支中。

## 验收与验证

- 旧 JSON 数据不含新字段时可正常加载；新字段保存、重启后恢复正确。
- 日期规则覆盖：无截止日期导入到创建日期、无创建日期回退当前本地日期、日期项不会跨天、用户自定义日期、具体时间导入/导出。
- 身份规则覆盖：重复导入更新原任务、重复同步更新原提醒、标题相同但 UUID 不同仍作为不同项目、唯一/歧义外部标识回退、任务关联副本不重复显示。
- 删除规则覆盖：关联任务删除后同步删除提醒、EventKit 删除失败时保留并重试队列、提醒已在 Mac 删除时不自动删除清单任务且导出不制造重复副本。
- UI 检查覆盖：四个图层开关状态持久化、Reminders 按所选列表和截止日期出现在月历、完成状态可辨识、同步面板授权与反馈清楚。
- 构建优化版 macOS 13 Universal 2 应用，并运行语义回归测试及 `git diff --check`。
- 代码与构建检查不能证明真实账户授权或 iCloud 同步。发布前仍需分别在 Ventura 和 macOS 14+ 上点击验证首次授权、创建、双向更新、删除重试以及无截止日期场景。

## 实施边界

- 新增专用 `ReminderSyncService`、提醒事项同步面板、月格展示模型和独立提醒事项关联/删除字段。
- 不重构 `CalendarSyncService`，不迁移既有日历关联数据，不改变日历事件规则，也不改写用户现有清单数据。
- 首版不新增后台自动同步；导入、导出和删除重试由用户点击提醒事项同步面板操作触发。

## 官方 API 参考

- [EventKit 授权 API 变化（TN3153）](https://developer.apple.com/documentation/technotes/tn3153-adopting-api-changes-for-eventkit-in-ios-macos-and-watchos)
- [访问 EventKit 事件存储](https://developer.apple.com/documentation/EventKit/accessing-the-event-store)
- [EKReminder 截止日期组件](https://developer.apple.com/documentation/eventkit/ekreminder/duedatecomponents?language=objc)
- [EKCalendarItem 唯一标识及完整同步后的标识变化](https://developer.apple.com/documentation/eventkit/ekcalendaritem/calendaritemidentifier?changes=_3&language=objc)
