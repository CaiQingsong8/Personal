# 桌面清单项目交接

> 最后更新：2026-10-23
> 交接状态：1.5.0 已发布并在本机前台打开；真实提醒事项账户和 macOS 13 实机验证待完成

## 当前状态

- [x] Mac 提醒事项已加入月历第四个图层，可切换显示；同步面板支持选择/创建列表、导入到清单、把清单事项同步到提醒事项。
- [x] 通过稳定任务 ID 更新已有提醒事项并传播删除，避免重复创建；与清单关联的提醒事项在月历中只显示清单版本。
- [x] 无截止日期的 Mac 提醒事项按创建日期导入为全天日期；没有创建日期时使用当天日期。清单同步不带时间时不生成跨日事件。
- [x] macOS 13 Ventura 使用旧 EventKit 提醒事项授权 API；macOS 14+ 使用完整访问 API。Intel 与 Apple Silicon 均包含在 Universal 2 构建中，最低系统版本为 13.0。
- [x] 桌面清单 1.5.0（build 15）已安装在 `/Applications/桌面清单.app`，通过 LaunchServices 启动并确认是前台应用；当前默认进入月历，可看到提醒事项入口。
- [ ] 尚未使用真实提醒事项/iCloud 账户点击验证首次授权、双向更新和删除传播；也尚未在接收方 macOS 13 电脑实测启动与权限流程。

## 仓库与发行

- 仓库：`CaiQingsong8/Personal`
- 分支：`codex/deskflow-calendar-sync`
- 提醒事项功能提交：`6a42e1879236530c30cb297b14c1f8b22d04d0c2`
- 1.5.0 发布提交：`1aef76c915bc1b68aac4e9d8b3d3682915e89e8b`
- Git 标签：`v1.5.0`（基于 1.5.0 发布提交；从 `v1.4.1` 延续）
- GitHub Release：<https://github.com/CaiQingsong8/Personal/releases/tag/v1.5.0>
- 发布包：`DeskFlow-1.5.0-macOS13-Universal.zip`
- 发布包 SHA-256：`a8f331ee4019266b402c3e76849f016db941cae995ef883f6ab5b4e9921db90c`
- 应用版本：1.5.0（15）；最低 macOS 13.0

## 验证

- Swift 日历/提醒事项语义回归测试通过；独立数据目录自测通过，未读取或修改用户真实任务数据。
- 全量源码类型检查通过；x86_64 和 arm64 编译通过；包签名和 ZIP 完整性检查通过。
- 安装包内二进制 SHA-256 与本次构建产物一致；系统确认 `/Applications/桌面清单.app` 的版本为 1.5.0 / build 15。
- 用户当前桌面会话已确认前台应用为 DeskFlow，且只运行一个 DeskFlow 实例。
- 本次未触碰 `~/Library/Application Support/DeskFlow`。

## 版本历史与注意事项

- `v1.4.1`（`c05356be44448b1292c0f2cf6fc362ef83fc2b23`）之前的日历 UUID 同步和默认 2 小时时段功能仍保留在 Git 历史。
- 旧版本地归档清理记录保存在 `a5ab71c`、`5ad3029`、`00855ba`；当前工作树仅保留最新版源码和构建目录。
- 当前仍为 ad-hoc 签名；其他 Mac 首次打开可能需要通过系统安全提示允许。
- 全天事件的结束值按次日零点排他边界表达。带自定义时间的提醒事项应保留用户设置，不自动折成全天事项。
- 用户数据目录 `~/Library/Application Support/DeskFlow` 不得随版本清理。
