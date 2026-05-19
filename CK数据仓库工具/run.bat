@echo off
chcp 65001 >nul
REM CK数据仓库文档生成脚本 (Windows)
echo =========================================
echo   CK数据仓库数据字典 - 文档生成工具
echo =========================================
echo.

cd /d "%~dp0"

REM Check Python
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未找到 python，请先安装 Python 3
    pause
    exit /b 1
)

REM Check Node.js
set NODE_OK=0
where node >nul 2>&1
if %errorlevel% equ 0 set NODE_OK=1

echo 📝 生成数据字典 Markdown...
python gen_dict.py
echo.

echo 🔍 生成可搜索 HTML 工具...
python gen_search_tool.py
echo.

if %NODE_OK%==1 (
    echo 📊 生成 PPT...
    if not exist "node_modules\pptxgenjs" (
        echo    安装 pptxgenjs...
        call npm install pptxgenjs 2>nul
    )
    python gen_ppt.py
    echo.
) else (
    echo ⚠️  未找到 Node.js，跳过 PPT 生成
    echo    如需 PPT，请先安装 Node.js 后重新运行
    echo.
)

echo =========================================
echo ✅ 生成完成！
echo.
echo   打开查询工具: 数据字典查询.html
echo   数据字典文档: CK数据仓库数据字典.md
if %NODE_OK%==1 echo   PPT演示文稿: CK数据仓库数据字典.pptx
echo =========================================
pause
