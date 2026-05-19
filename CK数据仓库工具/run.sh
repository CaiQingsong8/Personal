#!/bin/bash
# CK数据仓库文档生成脚本 (Mac/Linux)
echo "========================================="
echo "  CK数据仓库数据字典 - 文档生成工具"
echo "========================================="
echo ""

cd "$(dirname "$0")"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到 python3，请先安装 Python 3"
    exit 1
fi

# Check Node.js (for PPT)
NODE_OK=false
if command -v node &> /dev/null; then
    NODE_OK=true
fi

echo "📝 生成数据字典 Markdown..."
python3 gen_dict.py
echo ""

echo "🔍 生成可搜索 HTML 工具..."
python3 gen_search_tool.py
echo ""

if [ "$NODE_OK" = true ]; then
    echo "📊 生成 PPT..."
    if [ ! -d "node_modules/pptxgenjs" ]; then
        echo "   安装 pptxgenjs..."
        npm install pptxgenjs 2>/dev/null
    fi
    python3 gen_ppt.py
    echo ""
else
    echo "⚠️  未找到 Node.js，跳过 PPT 生成"
    echo "   如需 PPT，请先安装 Node.js 后重新运行"
    echo ""
fi

echo "========================================="
echo "✅ 生成完成！"
echo ""
echo "  打开查询工具: 数据字典查询.html"
echo "  数据字典文档: CK数据仓库数据字典.md"
if [ "$NODE_OK" = true ]; then
    echo "  PPT演示文稿: CK数据仓库数据字典.pptx"
fi
echo "========================================="
