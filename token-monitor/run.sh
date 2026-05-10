#!/bin/bash

# Token Monitor 启动脚本

echo "🚀 启动 Token Monitor..."

# 检查Python环境
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装"
    exit 1
fi

# 安装依赖
echo "📦 安装依赖..."
pip3 install -r requirements.txt

# 启动服务
echo "✅ 启动服务在 http://localhost:5000"
python3 app.py
