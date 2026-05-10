# AI平台Token消耗监控

本地Web应用，实时展示 mimo 和 deepseek 的token/余额使用情况。

## 功能

- **mimo**: 显示Token使用量（总Token、已使用、剩余、使用率）
- **deepseek**: 显示账户余额（总余额、已充值、赠送）
- 每60秒自动刷新
- 简洁单页界面

## 快速开始

### 1. 安装依赖

```bash
pip install -r requirements.txt
```

### 2. 配置API Key

复制配置文件示例并填入你的API Key：

```bash
cp config/deepseek.example.json config/deepseek.json
```

编辑 `config/deepseek.json`，填入你的deepseek API Key：

```json
{
  "api_key": "sk-your-api-key-here"
}
```

### 3. 启动服务

```bash
python app.py
```

访问 http://localhost:5001

## 配置说明

### deepseek

1. 访问 https://platform.deepseek.com/api_keys
2. 创建或复制你的API Key
3. 填入 `config/deepseek.json`

### mimo

mimo使用Cookie认证，需要：

1. 访问 https://platform.xiaomimimo.com/console/plan-manage
2. 登录后，从浏览器开发者工具复制Cookie
3. 保存到 `cookies/mimo.json`

## 技术栈

- 后端: Flask
- 前端: HTML/CSS/JavaScript
- 数据获取: requests + BeautifulSoup

## 项目结构

```
token-monitor/
├── app.py              # Flask主应用
├── requirements.txt    # Python依赖
├── run.sh             # 启动脚本
├── config/            # 配置文件
│   └── deepseek.example.json
├── cookies/           # Cookie存储（不上传）
├── scraper/           # 爬虫模块
│   ├── mimo.py
│   └── deepseek.py
├── static/            # 静态资源
│   ├── css/
│   └── js/
└── templates/         # HTML模板
    └── index.html
```

## 注意事项

- `config/deepseek.json` 和 `cookies/` 包含敏感信息，已添加到 `.gitignore`
- Cookie会过期，需要定期更新
- API Key是永久的，无需频繁更换
