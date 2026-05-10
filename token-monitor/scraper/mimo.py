import requests
from bs4 import BeautifulSoup
import json
import os
import re
from datetime import datetime

class MimoScraper:
    """mimo平台网页爬取类"""

    def __init__(self, cookie_file=None):
        self.base_url = 'https://platform.xiaomimimo.com'
        self.usage_url = f'{self.base_url}/console/plan-manage'
        # 使用绝对路径
        if cookie_file is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
            self.cookie_file = os.path.join(base_dir, 'cookies', 'mimo.json')
        else:
            self.cookie_file = cookie_file
        self.session = requests.Session()
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
            'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        }
        self.session.headers.update(self.headers)
        self._load_cookies()

    def _load_cookies(self):
        """从文件加载Cookie"""
        if os.path.exists(self.cookie_file):
            try:
                with open(self.cookie_file, 'r') as f:
                    cookies = json.load(f)
                    for cookie in cookies:
                        self.session.cookies.set(cookie['name'], cookie['value'], domain=cookie.get('domain', ''))
                print(f"✅ 已加载mimo Cookie")
            except Exception as e:
                print(f"⚠️ 加载Cookie失败: {e}")

    def _save_cookies(self, cookies):
        """保存Cookie到文件"""
        try:
            os.makedirs(os.path.dirname(self.cookie_file), exist_ok=True)
            cookie_list = []
            for cookie in cookies:
                cookie_list.append({
                    'name': cookie['name'],
                    'value': cookie['value'],
                    'domain': cookie.get('domain', ''),
                    'path': cookie.get('path', '/')
                })
            with open(self.cookie_file, 'w') as f:
                json.dump(cookie_list, f, indent=2)
            print(f"✅ 已保存mimo Cookie")
        except Exception as e:
            print(f"❌ 保存Cookie失败: {e}")

    def set_cookies(self, cookie_string):
        """手动设置Cookie（从浏览器复制）"""
        try:
            cookies = []
            for item in cookie_string.split(';'):
                item = item.strip()
                if '=' in item:
                    name, value = item.split('=', 1)
                    cookies.append({'name': name.strip(), 'value': value.strip()})
            self._save_cookies(cookies)
            for cookie in cookies:
                self.session.cookies.set(cookie['name'], cookie['value'])
            return True
        except Exception as e:
            print(f"❌ 设置Cookie失败: {e}")
            return False

    def get_token_usage(self):
        """获取token消耗数据"""
        try:
            # 调用实际的API端点
            api_url = f'{self.base_url}/api/v1/tokenPlan/usage'
            headers = {
                'accept': '*/*',
                'accept-language': 'zh',
                'content-type': 'application/json',
                'referer': self.usage_url,
                'user-agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/148.0.0.0 Safari/537.36',
                'x-timezone': 'Asia/Shanghai',
            }
            response = self.session.get(api_url, headers=headers, timeout=15)

            if response.status_code == 200:
                data = response.json()
                return self._parse_api_response(data)
            elif response.status_code == 401 or response.status_code == 403:
                return {
                    'success': False,
                    'error': 'Cookie已过期，请重新登录并更新Cookie',
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

    def _parse_api_response(self, data):
        """解析API返回的JSON数据"""
        try:
            # 根据实际API返回格式解析
            # data结构: {"code":0,"data":{"monthUsage":{"items":[{"used":...,"limit":...,"percent":...}]}}}
            month_usage = data.get('data', {}).get('monthUsage', {})
            items = month_usage.get('items', [])

            result = {
                'platform': 'mimo',
                'total_tokens': 0,
                'used_tokens': 0,
                'remaining_tokens': 0,
                'usage_rate': 0,
                'last_updated': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

            if items:
                item = items[0]
                result['total_tokens'] = item.get('limit', 0)
                result['used_tokens'] = item.get('used', 0)
                result['remaining_tokens'] = result['total_tokens'] - result['used_tokens']
                result['usage_rate'] = round(item.get('percent', 0) * 100, 2)

            return {
                'success': True,
                'error': None,
                'data': result
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'API数据解析错误: {str(e)}',
                'data': None
            }

    def _fallback_html_parse(self):
        """备用HTML解析方法"""
        try:
            response = self.session.get(self.usage_url, timeout=15)
            if response.status_code == 200:
                return self._parse_usage_page(response.text)
            return {
                'success': False,
                'error': f'请求失败: HTTP {response.status_code}',
                'data': None
            }
        except Exception as e:
            return {
                'success': False,
                'error': f'请求失败: {str(e)}',
                'data': None
            }

    def _parse_usage_page(self, html):
        """解析使用情况页面 - 从HTML提取数据"""
        try:
            soup = BeautifulSoup(html, 'html.parser')

            result = {
                'platform': 'mimo',
                'total_tokens': 0,
                'used_tokens': 0,
                'remaining_tokens': 0,
                'usage_rate': 0,
                'last_updated': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
            }

            # 从HTML中查找数据：64,828,737 / 700,000,000 已使用 9.0%
            # 使用正则表达式提取数字
            import re

            # 查找类似 "64,828,737 / 700,000,000" 的模式
            text = soup.get_text()
            match = re.search(r'([\d,]+)\s*/\s*([\d,]+)', text)
            if match:
                result['used_tokens'] = self._parse_number(match.group(1))
                result['total_tokens'] = self._parse_number(match.group(2))
                result['remaining_tokens'] = result['total_tokens'] - result['used_tokens']
                if result['total_tokens'] > 0:
                    result['usage_rate'] = round(
                        (result['used_tokens'] / result['total_tokens']) * 100, 2
                    )

            # 如果没有找到，尝试其他模式
            if result['total_tokens'] == 0:
                # 查找百分比
                percent_match = re.search(r'已使用\s*([\d.]+)%', text)
                if percent_match:
                    result['usage_rate'] = float(percent_match.group(1))

            if result['total_tokens'] == 0:
                return {
                    'success': False,
                    'error': '无法解析页面数据，请检查页面结构或Cookie是否有效',
                    'data': result,
                    'html_preview': html[:500]
                }

            return {
                'success': True,
                'error': None,
                'data': result
            }

        except Exception as e:
            return {
                'success': False,
                'error': f'页面解析错误: {str(e)}',
                'data': None
            }

    def _parse_number(self, text):
        """解析数字文本"""
        try:
            # 移除逗号、空格等非数字字符
            cleaned = text.replace(',', '').replace(' ', '').strip()
            return int(cleaned)
        except:
            return 0

    def check_login_status(self):
        """检查登录状态"""
        try:
            response = self.session.get(self.usage_url, timeout=10, allow_redirects=False)
            if response.status_code == 200:
                return {'logged_in': True, 'message': '已登录'}
            elif response.status_code in [301, 302]:
                return {'logged_in': False, 'message': '未登录，需要重定向到登录页'}
            else:
                return {'logged_in': False, 'message': f'状态码: {response.status_code}'}
        except Exception as e:
            return {'logged_in': False, 'message': f'检查失败: {str(e)}'}
