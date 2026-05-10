import requests
import json
import os
from datetime import datetime

class DeepSeekScraper:
    """deepseek平台余额查询类"""

    def __init__(self, config_file=None):
        self.balance_url = 'https://api.deepseek.com/user/balance'
        # 使用绝对路径
        if config_file is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            self.config_file = os.path.join(base_dir, 'config', 'deepseek.json')
        else:
            self.config_file = config_file
        self.session = requests.Session()
        self.headers = {
            'accept': 'application/json',
            'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        }
        self.session.headers.update(self.headers)
        self._load_config()

    def _load_config(self):
        """从配置文件加载API Key"""
        if os.path.exists(self.config_file):
            try:
                with open(self.config_file, 'r') as f:
                    config = json.load(f)
                    self.api_key = config.get('api_key', '')
                print(f"✅ 已加载deepseek配置")
            except Exception as e:
                print(f"⚠️ 加载配置失败: {e}")
                self.api_key = ''
        else:
            self.api_key = ''

    def set_api_key(self, api_key):
        """设置API Key"""
        self.api_key = api_key
        self._save_config()

    def _save_config(self):
        """保存配置到文件"""
        try:
            os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
            config = {
                'api_key': self.api_key
            }
            with open(self.config_file, 'w') as f:
                json.dump(config, f, indent=2)
            print(f"✅ 已保存deepseek配置")
        except Exception as e:
            print(f"❌ 保存配置失败: {e}")

    def get_token_usage(self):
        """获取余额数据"""
        try:
            if not self.api_key:
                return {
                    'success': False,
                    'error': '未配置API Key',
                    'data': None
                }

            headers = {
                'accept': 'application/json',
                'authorization': f'Bearer {self.api_key}',
            }

            response = self.session.get(self.balance_url, headers=headers, timeout=15)

            if response.status_code == 200:
                data = response.json()
                return self._parse_balance_response(data)
            elif response.status_code == 401:
                return {
                    'success': False,
                    'error': 'API Key无效或已过期',
                    'data': None
                }
            else:
                return {
                    'success': False,
                    'error': f'请求失败: HTTP {response.status_code}',
                    'data': None
                }

        except requests.exceptions.RequestException as e:
            return {
                'success': False,
                'error': f'网络请求错误: {str(e)}',
                'data': None
            }

    def _parse_balance_response(self, data):
        """解析余额API返回的数据"""
        try:
            # data结构: {"is_available":true,"balance_infos":[{"currency":"CNY","total_balance":"18.33",...}]}
            balance_infos = data.get('balance_infos', [])

            result = {
                'platform': 'deepseek',
                'is_available': data.get('is_available', False),
                'currency': 'CNY',
                'total_balance': 0,
                'granted_balance': 0,
                'topped_up_balance': 0,
                'last_updated': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

            if balance_infos:
                balance = balance_infos[0]
                result['currency'] = balance.get('currency', 'CNY')
                result['total_balance'] = float(balance.get('total_balance', 0))
                result['granted_balance'] = float(balance.get('granted_balance', 0))
                result['topped_up_balance'] = float(balance.get('topped_up_balance', 0))

            return {
                'success': True,
                'error': None,
                'data': result
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'数据解析错误: {str(e)}',
                'data': None
            }
