# CK数据仓库数据字典

ClickHouse 数据仓库文档工具，包含数据字典、PPT、血缘关系图和可搜索查询工具。

## 快速开始

### 方式一：直接打开查询工具（推荐）

双击 `数据字典查询.html` 即可在浏览器中打开，无需安装任何软件。

### 方式二：重新生成文档

如需修改数据源后重新生成，需要 Python 3 和 Node.js 环境。

```bash
# 安装依赖
npm install pptxgenjs

# 生成数据字典 Markdown
python3 gen_dict.py

# 生成 PPT
python3 gen_ppt.py

# 生成可搜索 HTML 工具
python3 gen_search_tool.py
```

**Windows 用户**：用 `python` 替代 `python3`

## 文件说明

| 文件 | 说明 |
|------|------|
| `数据字典查询.html` | 可搜索的数据字典工具（直接双击打开） |
| `CK数据仓库数据字典.md` | 完整数据字典 Markdown 文档 |
| `CK数据仓库数据字典.pptx` | 数据仓库架构 PPT |
| `script.sql` | 87张表 + 4个视图的建表语句 |
| `workflow_1777516820540.json` | 海豚调度工作流定义（10个工作流） |
| `gen_dict.py` | 生成 MD 数据字典的脚本 |
| `gen_ppt.py` | 生成 PPT 的脚本 |
| `gen_search_tool.py` | 生成 HTML 查询工具的脚本 |

## 查询工具功能

- **数据表 Tab**：87张表，按层级筛选（DIM/DWD/DWS/ADS/ODS）
- **视图 Tab**：4个视图独立展示
- **工作流 Tab**：10个调度工作流，含可视化血缘图
- **搜索**：支持表名、字段名、中文名、注释搜索
- **SQL 查看**：点击「建表语句 DDL」或「取数 SQL」查看带语法高亮的 SQL
- **血缘图**：工作流中点击「可视化血缘图」查看表间依赖关系

## 环境要求

- 生成工具：Python 3.6+、Node.js 14+
- 查看工具：任意现代浏览器（Chrome/Edge/Safari/Firefox）
