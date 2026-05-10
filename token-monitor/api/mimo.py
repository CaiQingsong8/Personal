import requests
import json
from datetime import datetime

class MimoAPI:
    """mimo平台API对接类"""

    def __init__(self, api_key, base_url="https://platform.xiaomimimo.com/api"):
        self.api_key = api_key
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json'
        }

    def get_token_usage(self):
        """获取token消耗数据"""
        try:
            # 调用mimo API获取token使用情况
            response = requests.get(
                f'{self.base_url}/v1/usage',
                headers=self.headers,
                timeout=10
            )

            if response.status_code == 200:
                data = response.json()
                return self._parse_token_data(data)
            else:
                return {
                    'success': False,
                    'error': f'API请求失败: {response.status_code}',
                    'data': None
                }

        except requests.exceptions.RequestException as e:
            return {
                'success': False,
                'error': f'网络请求错误: {str(e)}',
                'data': None
            }

    def _parse_token_data(self, data):
        """解析API返回的数据"""
        try:
            # 根据mimo API的实际返回格式解析数据
            # 这里需要根据实际API文档调整
            result = {
                'platform': 'mimo',
                'total_tokens': data.get('total_tokens', 0),
                'used_tokens': data.get('used_tokens', 0),
                'remaining_tokens': data.get('remaining_tokens', 0),
                'usage_history': data.get('usage_history', []),
                'last_updated': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

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

    def get_balance(self):
        """获取账户余额"""
        try:
            response = requests.get(
                f'{self.base_url}/v1/balance',
                headers=self.headers,
                timeout=10
            )

            if response.status_code == 200:
                data = response.json()
                return {
                    'success': True,
                    'error': None,
                    'data': {
                        'platform': 'mimo',
                        'balance': data.get('balance', 0),
                        'currency': data.get('currency', 'CNY')
                    }
                }
            else:
                return {
                    'success': False,
                    'error': f'API请求失败: {response.status_code}',
                    'data': None
                }

        except requests.exceptions.RequestException as e:
            return {
                'success': False,
                'error': f'网络请求错误: {str(e)}',
                'data': None
            }
