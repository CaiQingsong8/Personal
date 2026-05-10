// Token Monitor 前端交互逻辑

// 全局变量
let usageChart = null;
const API_BASE_URL = '';

// 页面加载完成后初始化
document.addEventListener('DOMContentLoaded', function() {
    initChart();
    refreshAll();

    // 每30秒自动刷新
    setInterval(refreshAll, 30000);
});

// 初始化图表
function initChart() {
    const ctx = document.getElementById('usageChart').getContext('2d');
    usageChart = new Chart(ctx, {
        type: 'line',
        data: {
            labels: [],
            datasets: [
                {
                    label: 'mimo Token消耗',
                    data: [],
                    borderColor: '#667eea',
                    backgroundColor: 'rgba(102, 126, 234, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4
                },
                {
                    label: 'deepseek Token消耗',
                    data: [],
                    borderColor: '#f5576c',
                    backgroundColor: 'rgba(245, 87, 108, 0.1)',
                    borderWidth: 3,
                    fill: true,
                    tension: 0.4
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'top',
                    labels: {
                        font: {
                            size: 14
                        }
                    }
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    grid: {
                        color: 'rgba(0, 0, 0, 0.1)'
                    }
                },
                x: {
                    grid: {
                        color: 'rgba(0, 0, 0, 0.1)'
                    }
                }
            }
        }
    });
}

// 设置Cookie
async function setCookie(platform) {
    const cookieInput = document.getElementById(`${platform}Cookie`);
    const cookieString = cookieInput.value.trim();

    if (!cookieString) {
        updateStatus('error', '请输入Cookie');
        return;
    }

    try {
        const response = await fetch(`${API_BASE_URL}/api/${platform}/cookie`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ cookie: cookieString })
        });

        const data = await response.json();

        if (data.success) {
            updateStatus('success', `${platform} Cookie设置成功`);
            cookieInput.value = '';
            // 设置成功后立即刷新数据
            refreshAll();
        } else {
            updateStatus('error', `${platform} Cookie设置失败: ${data.error}`);
        }
    } catch (error) {
        console.error('设置Cookie失败:', error);
        updateStatus('error', '网络请求失败');
    }
}

// 刷新所有数据
async function refreshAll() {
    updateStatus('loading', '正在刷新数据...');

    try {
        const response = await fetch(`${API_BASE_URL}/api/refresh`);
        const data = await response.json();

        if (data.success) {
            // 更新mimo数据
            if (data.data.results.mimo.success) {
                updateMimoCard(data.data.results.mimo.data);
            } else {
                showError('mimoCard', data.data.results.mimo.error);
            }

            // 更新deepseek数据
            if (data.data.results.deepseek.success) {
                updateDeepseekCard(data.data.results.deepseek.data);
            } else {
                showError('deepseekCard', data.data.results.deepseek.error);
            }

            updateStatus('success', '数据刷新成功');
        } else {
            updateStatus('error', `刷新失败: ${data.error}`);
        }
    } catch (error) {
        console.error('刷新数据失败:', error);
        updateStatus('error', '网络请求失败');
    }
}

// 更新mimo卡片
function updateMimoCard(data) {
    document.getElementById('mimoTotal').textContent = formatNumber(data.total_tokens);
    document.getElementById('mimoUsed').textContent = formatNumber(data.used_tokens);
    document.getElementById('mimoRemaining').textContent = formatNumber(data.remaining_tokens);

    const usageRate = data.total_tokens > 0
        ? ((data.used_tokens / data.total_tokens) * 100).toFixed(1)
        : 0;
    document.getElementById('mimoUsageRate').textContent = `${usageRate}%`;

    // 更新进度条
    const progressBar = document.getElementById('mimoProgress');
    progressBar.style.width = `${usageRate}%`;

    // 更新时间
    document.getElementById('mimoLastUpdated').textContent = data.last_updated;

    // 更新图表
    updateChart('mimo', data);
}

// 更新deepseek卡片
function updateDeepseekCard(data) {
    document.getElementById('deepseekTotal').textContent = formatNumber(data.total_tokens);
    document.getElementById('deepseekUsed').textContent = formatNumber(data.used_tokens);
    document.getElementById('deepseekRemaining').textContent = formatNumber(data.remaining_tokens);

    const usageRate = data.total_tokens > 0
        ? ((data.used_tokens / data.total_tokens) * 100).toFixed(1)
        : 0;
    document.getElementById('deepseekUsageRate').textContent = `${usageRate}%`;

    // 更新进度条
    const progressBar = document.getElementById('deepseekProgress');
    progressBar.style.width = `${usageRate}%`;

    // 更新时间
    document.getElementById('deepseekLastUpdated').textContent = data.last_updated;

    // 更新图表
    updateChart('deepseek', data);
}

// 更新图表
function updateChart(platform, data) {
    if (!usageChart) return;

    const now = new Date().toLocaleTimeString('zh-CN', {
        hour: '2-digit',
        minute: '2-digit'
    });

    // 添加新数据点
    usageChart.data.labels.push(now);

    if (platform === 'mimo') {
        usageChart.data.datasets[0].data.push(data.used_tokens);
        // 保持与mimo数据点数量一致
        if (usageChart.data.datasets[1].data.length < usageChart.data.datasets[0].data.length) {
            usageChart.data.datasets[1].data.push(null);
        }
    } else if (platform === 'deepseek') {
        usageChart.data.datasets[1].data.push(data.used_tokens);
        // 保持与deepseek数据点数量一致
        if (usageChart.data.datasets[0].data.length < usageChart.data.datasets[1].data.length) {
            usageChart.data.datasets[0].data.push(null);
        }
    }

    // 只保留最近10个数据点
    if (usageChart.data.labels.length > 10) {
        usageChart.data.labels.shift();
        usageChart.data.datasets[0].data.shift();
        usageChart.data.datasets[1].data.shift();
    }

    usageChart.update();
}

// 显示错误状态
function showError(cardId, errorMessage) {
    const card = document.getElementById(cardId);
    const cardBody = card.querySelector('.card-body');

    // 清空数据
    const statValues = cardBody.querySelectorAll('.stat-value');
    statValues.forEach(el => el.textContent = '--');

    // 重置进度条
    const progressBar = cardBody.querySelector('.progress-fill');
    progressBar.style.width = '0%';

    // 显示错误信息
    const lastUpdated = cardBody.querySelector('.last-updated');
    lastUpdated.innerHTML = `<span class="error">${errorMessage}</span>`;
}

// 更新状态指示器
function updateStatus(type, message) {
    const statusDot = document.querySelector('.status-dot');
    const statusText = document.querySelector('.status-text');

    statusText.textContent = message;

    switch (type) {
        case 'loading':
            statusDot.style.background = '#fbbf24';
            statusDot.style.animation = 'pulse 1s infinite';
            break;
        case 'success':
            statusDot.style.background = '#4ade80';
            statusDot.style.animation = 'pulse 2s infinite';
            break;
        case 'error':
            statusDot.style.background = '#ef4444';
            statusDot.style.animation = 'none';
            break;
    }
}

// 格式化数字
function formatNumber(num) {
    if (num === null || num === undefined) return '--';
    return num.toLocaleString('zh-CN');
}

// 手动刷新按钮点击事件
function manualRefresh() {
    refreshAll();
}
