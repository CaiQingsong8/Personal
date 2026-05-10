from flask import Flask, jsonify, render_template, request
from flask_cors import CORS
import os
import json
import logging
from scraper import MimoScraper
from scraper.deepseek import DeepSeekScraper

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# 初始化爬虫
mimo_scraper = MimoScraper()
deepseek_scraper = DeepSeekScraper()

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/health')
def health():
    return jsonify({'status': 'ok', 'message': 'Token Monitor is running'})

@app.route('/api/mimo/token')
def get_mimo_token():
    """获取mimo平台token消耗数据"""
    try:
        logger.info("获取mimo token消耗数据")
        result = mimo_scraper.get_token_usage()
        if result['success']:
            return jsonify(result)
        else:
            logger.error(f"获取mimo token失败: {result['error']}")
            return jsonify(result), 400
    except Exception as e:
        logger.error(f"获取mimo token异常: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'服务器错误: {str(e)}',
            'data': None
        }), 500

@app.route('/api/deepseek/token')
def get_deepseek_token():
    """获取deepseek平台token消耗数据"""
    try:
        logger.info("获取deepseek token消耗数据")
        result = deepseek_scraper.get_token_usage()
        if result['success']:
            return jsonify(result)
        else:
            logger.error(f"获取deepseek token失败: {result['error']}")
            return jsonify(result), 400
    except Exception as e:
        logger.error(f"获取deepseek token异常: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'服务器错误: {str(e)}',
            'data': None
        }), 500

@app.route('/api/refresh')
def refresh_all():
    """手动刷新所有平台数据"""
    try:
        logger.info("手动刷新所有平台数据")
        results = {
            'mimo': mimo_scraper.get_token_usage(),
            'deepseek': deepseek_scraper.get_token_usage()
        }

        success_count = sum(1 for r in results.values() if r['success'])
        total_count = len(results)

        return jsonify({
            'success': True,
            'error': None,
            'data': {
                'results': results,
                'summary': {
                    'success_count': success_count,
                    'total_count': total_count,
                    'all_success': success_count == total_count
                }
            }
        })
    except Exception as e:
        logger.error(f"刷新数据异常: {str(e)}")
        return jsonify({
            'success': False,
            'error': f'服务器错误: {str(e)}',
            'data': None
        }), 500

@app.route('/api/mimo/cookie', methods=['POST'])
def set_mimo_cookie():
    """设置mimo Cookie"""
    try:
        data = request.get_json()
        cookie_string = data.get('cookie', '')
        if not cookie_string:
            return jsonify({'success': False, 'error': 'Cookie不能为空'}), 400

        success = mimo_scraper.set_cookies(cookie_string)
        if success:
            return jsonify({'success': True, 'message': 'Cookie设置成功'})
        else:
            return jsonify({'success': False, 'error': 'Cookie设置失败'}), 400
    except Exception as e:
        logger.error(f"设置mimo Cookie异常: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/deepseek/cookie', methods=['POST'])
def set_deepseek_cookie():
    """设置deepseek Cookie"""
    try:
        data = request.get_json()
        cookie_string = data.get('cookie', '')
        if not cookie_string:
            return jsonify({'success': False, 'error': 'Cookie不能为空'}), 400

        success = deepseek_scraper.set_cookies(cookie_string)
        if success:
            return jsonify({'success': True, 'message': 'Cookie设置成功'})
        else:
            return jsonify({'success': False, 'error': 'Cookie设置失败'}), 400
    except Exception as e:
        logger.error(f"设置deepseek Cookie异常: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/mimo/login-status')
def check_mimo_login():
    """检查mimo登录状态"""
    try:
        result = mimo_scraper.check_login_status()
        return jsonify({'success': True, 'data': result})
    except Exception as e:
        logger.error(f"检查mimo登录状态异常: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/deepseek/login-status')
def check_deepseek_login():
    """检查deepseek登录状态"""
    try:
        result = deepseek_scraper.check_login_status()
        return jsonify({'success': True, 'data': result})
    except Exception as e:
        logger.error(f"检查deepseek登录状态异常: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    logger.info(f"启动Token Monitor服务，端口: {port}")
    app.run(host='0.0.0.0', port=port, debug=True)
