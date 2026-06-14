<script def>
{
  "navigationBarTitleText": "滑动事件测试"
}
</script>

<script setup>
import Tools from '../../Tools/tools.js';

const MAX_LOGS = 6;

function formatTime(date) {
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return `${hours}:${minutes}:${seconds}`;
}

export default {
  data: {
    statusText: '等待前滑或后滑',
    lastPhase: '-',
    lastCode: '-',
    lastAction: '-',
    forwardCount: 0,
    backwardCount: 0,
    unknownCount: 0,
    logLine0: '',
    logLine1: '',
    logLine2: '',
    logLine3: '',
    logLine4: '',
    logLine5: ''
  },
  pushLog(text) {
    const logs = this.logs || [];
    const nextLogs = [text].concat(logs).slice(0, MAX_LOGS);

    this.logs = nextLogs;
    this.setData({
      logLine0: nextLogs[0] || '',
      logLine1: nextLogs[1] || '',
      logLine2: nextLogs[2] || '',
      logLine3: nextLogs[3] || '',
      logLine4: nextLogs[4] || '',
      logLine5: nextLogs[5] || ''
    });
  },
  handleSlideEvent(event, phase) {
    const slideEvent = Tools.getSlideEvent(event);
    const code = slideEvent.code;
    const slide = slideEvent.slide;
    const time = formatTime(new Date());
    const codeText = String(code || '-');
    let action = '未识别';
    const nextData = {
      lastPhase: phase,
      lastCode: codeText
    };

    if (slide === 'forward') {
      Tools.preventDefault(event);
      action = '前滑';
      nextData.forwardCount = this.data.forwardCount + 1;
    } else if (slide === 'backward') {
      Tools.preventDefault(event);
      action = '后滑';
      nextData.backwardCount = this.data.backwardCount + 1;
    } else {
      nextData.unknownCount = this.data.unknownCount + 1;
    }

    if (action === '后滑') {
      nextData.statusText = '后滑触发成功';
    } else if (action === '前滑') {
      nextData.statusText = '前滑触发成功';
    } else {
      nextData.statusText = `收到未识别事件：${codeText}`;
    }

    nextData.lastAction = action;
    this.setData(nextData);
    this.pushLog(`${time} ${phase} code=${codeText} action=${action}`);
  },
  onKeyUp(event) {
    this.handleSlideEvent(event, 'keyup');
  }
}
</script>

<page>
  <view class="page">
    <view class="panel">
      <text class="title">滑动事件测试</text>
      <text class="status">{{ statusText }}</text>

      <view class="grid">
        <view class="metric">
          <text class="metric-value">{{ forwardCount }}</text>
          <text class="metric-label">前滑</text>
        </view>
        <view class="metric">
          <text class="metric-value">{{ backwardCount }}</text>
          <text class="metric-label">后滑</text>
        </view>
        <view class="metric">
          <text class="metric-value">{{ unknownCount }}</text>
          <text class="metric-label">其他</text>
        </view>
      </view>

      <view class="details">
        <text class="detail">phase: {{ lastPhase }}</text>
        <text class="detail">code: {{ lastCode }}</text>
        <text class="detail">action: {{ lastAction }}</text>
      </view>

      <view class="logs">
        <text class="log">{{ logLine0 }}</text>
        <text class="log">{{ logLine1 }}</text>
        <text class="log">{{ logLine2 }}</text>
        <text class="log">{{ logLine3 }}</text>
        <text class="log">{{ logLine4 }}</text>
        <text class="log">{{ logLine5 }}</text>
      </view>
    </view>
  </view>
</page>

<style>
.page {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  box-sizing: border-box;
  width: 100%;
  height: 100vh;
  padding: 4px 16px 4px;
  background: #071b14;
  color: #d8ffb0;
  overflow: hidden;
}

.panel {
  display: flex;
  flex-direction: column;
  width: 420px;
  max-width: 100%;
}

.title {
  color: #e9ff98;
  font-size: 18px;
  line-height: 22px;
  font-weight: 700;
  text-align: center;
}

.status {
  margin-top: 1px;
  color: #8dff7a;
  font-size: 11px;
  line-height: 13px;
  text-align: center;
}

.grid {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 4px;
}

.metric {
  display: flex;
  flex: 1;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 50px;
  border: 2px solid #2f8b42;
  border-radius: 8px;
  background: #0d2b1d;
}

.metric-value {
  color: #e9ff98;
  font-size: 16px;
  line-height: 18px;
  font-weight: 700;
}

.metric-label {
  margin-top: 0;
  color: #94df72;
  font-size: 10px;
  line-height: 12px;
}

.details {
  display: flex;
  flex-direction: column;
  margin-top: 4px;
  padding: 4px 8px;
  border: 1px solid #2f8b42;
  border-radius: 8px;
  background: #092317;
}

.detail {
  color: #caff8d;
  font-size: 10px;
  line-height: 12px;
}

.logs {
  display: flex;
  flex-direction: column;
  min-height: 30px;
  margin-top: 4px;
  padding: 4px 8px;
  border: 1px solid #235f34;
  border-radius: 8px;
  background: #05160f;
}

.log {
  color: #8ccf70;
  font-family: Consolas, Monaco, "Courier New", monospace;
  font-size: 8px;
  line-height: 9px;
  white-space: nowrap;
}
</style>
