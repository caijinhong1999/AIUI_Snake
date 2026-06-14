<script def>
{
  "navigationBarTitleText": "IMU 测试"
}
</script>

<script setup>
import Tools from '../../Tools/tools.js';

const MAX_LOGS = 6;

function formatNumber(value) {
  if (value === null || value === undefined || Number.isNaN(value)) {
    return '-';
  }

  return String(Math.round(value));
}

function formatTime(date) {
  const hours = String(date.getHours()).padStart(2, '0');
  const minutes = String(date.getMinutes()).padStart(2, '0');
  const seconds = String(date.getSeconds()).padStart(2, '0');

  return `${hours}:${minutes}:${seconds}`;
}

export default {
  data: {
    statusText: '正在等待 IMU',
    xText: '-',
    yText: '-',
    zText: '-',
    speedText: '-',
    actionText: '未触发',
    baseText: '未校准',
    leftClass: '',
    rightClass: '',
    upClass: '',
    downClass: '',
    leftCount: 0,
    rightCount: 0,
    upCount: 0,
    downCount: 0,
    logLine0: '',
    logLine1: '',
    logLine2: '',
    logLine3: '',
    logLine4: '',
    logLine5: ''
  },
  onLoad() {
    this.startSensor();
  },
  onUnload() {
    this.stopSensor();
  },
  onHide() {
    this.stopSensor();
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
  startSensor() {
    this.stopSensor();
    this.headTracker = Tools.createHeadDirectionTracker({
      onActivate: () => {
        this.setData({
          statusText: '陀螺仪已启动，请从初始位置转头',
          baseText: 'gyro x 0 / y 0 / z 0'
        });
        this.pushLog(`${formatTime(new Date())} gyro active`);
      },
      onError: (message) => {
        this.setData({
          statusText: message
        });
        this.pushLog(`${formatTime(new Date())} gyro error ${message}`);
      },
      onReading: (reading) => {
        this.handleReading(reading);
      },
      onAction: (action, reading) => {
        this.triggerAction(action, reading.axisDelta);
      },
      onReset: () => {
        this.setData({
          statusText: '重新校准中，请保持头部初始位置',
          actionText: '未触发',
          baseText: 'gyro x 0 / y 0 / z 0',
          xText: '0',
          yText: '0',
          zText: '0',
          speedText: '-',
          leftClass: '',
          rightClass: '',
          upClass: '',
          downClass: ''
        });
      }
    });
    this.headTracker.start();
  },
  stopSensor() {
    if (this.headTracker) {
      this.headTracker.stop();
    }

    this.headTracker = null;
  },
  resetBase() {
    if (this.headTracker) {
      this.headTracker.reset();
    }
  },
  getActionText(action) {
    const actionMap = {
      left: '头部左转',
      right: '头部右转',
      up: '头部向上',
      down: '头部向下'
    };

    return actionMap[action] || '未触发';
  },
  updateActiveClass(action) {
    this.setData({
      leftClass: action === 'left' ? 'active' : '',
      rightClass: action === 'right' ? 'active' : '',
      upClass: action === 'up' ? 'active' : '',
      downClass: action === 'down' ? 'active' : ''
    });
  },
  triggerAction(action, axisDelta) {
    const nextData = {
      actionText: this.getActionText(action),
      statusText: `${this.getActionText(action)} 已识别`
    };

    if (action === 'left') {
      nextData.leftCount = this.data.leftCount + 1;
    } else if (action === 'right') {
      nextData.rightCount = this.data.rightCount + 1;
    } else if (action === 'up') {
      nextData.upCount = this.data.upCount + 1;
    } else if (action === 'down') {
      nextData.downCount = this.data.downCount + 1;
    }

    this.setData(nextData);
    this.updateActiveClass(action);
    this.pushLog(`${formatTime(new Date())} ${this.getActionText(action)} x=${formatNumber(axisDelta.x)} y=${formatNumber(axisDelta.y)} z=${formatNumber(axisDelta.z)}`);
  },
  handleReading(reading) {
    const axisDelta = reading.axisDelta;
    const axisSpeed = reading.axisSpeed;

    if (reading.isInitialized) {
      this.setData({
        statusText: '陀螺仪已建立初始位置',
        baseText: 'gyro x 0 / y 0 / z 0',
        xText: '0',
        yText: '0',
        zText: '0',
        speedText: '-'
      });
      return;
    }

    if (reading.isCentered) {
      this.updateActiveClass('');
      this.setData({
        statusText: '陀螺仪已回中，等待头动',
        actionText: '未触发'
      });
    }

    this.setData({
      xText: formatNumber(axisDelta.x),
      yText: formatNumber(axisDelta.y),
      zText: formatNumber(axisDelta.z),
      speedText: axisSpeed ? `x ${formatNumber(axisSpeed.x)} / y ${formatNumber(axisSpeed.y)} / z ${formatNumber(axisSpeed.z)}` : '-'
    });
  }
}
</script>

<page>
  <view class="page">
    <view class="panel">
      <text class="title">IMU 头动测试</text>
      <text class="status">{{ statusText }}</text>

      <view class="direction-grid">
        <view class="direction up {{ upClass }}">
          <text class="direction-title">向上</text>
          <text class="direction-count">{{ upCount }}</text>
        </view>
        <view class="direction-row">
          <view class="direction {{ leftClass }}">
            <text class="direction-title">左转</text>
            <text class="direction-count">{{ leftCount }}</text>
          </view>
          <view class="direction {{ rightClass }}">
            <text class="direction-title">右转</text>
            <text class="direction-count">{{ rightCount }}</text>
          </view>
        </view>
        <view class="direction down {{ downClass }}">
          <text class="direction-title">向下</text>
          <text class="direction-count">{{ downCount }}</text>
        </view>
      </view>

      <view class="details">
        <text class="detail">action: {{ actionText }}</text>
        <text class="detail">base: {{ baseText }}</text>
        <text class="detail">relative: x {{ xText }} / y {{ yText }} / z {{ zText }}</text>
        <text class="detail">speed: {{ speedText }}</text>
      </view>

      <view class="button" bindtap="resetBase">
        <text class="button-text">重新校准</text>
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
  padding: 4px 16px;
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

.direction-grid {
  display: flex;
  flex-direction: column;
  gap: 4px;
  margin-top: 4px;
}

.direction-row {
  display: flex;
  gap: 4px;
}

.direction {
  display: flex;
  flex: 1;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  border: 2px solid #2f8b42;
  border-radius: 8px;
  background: #0d2b1d;
}

.direction.up,
.direction.down {
  width: 50%;
  align-self: center;
}

.direction.active {
  border-color: #e9ff98;
  background: #215124;
}

.direction-title {
  color: #e9ff98;
  font-size: 13px;
  line-height: 16px;
  font-weight: 700;
}

.direction-count {
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

.button {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 28px;
  margin-top: 4px;
  border: 1px solid #4eb65b;
  border-radius: 8px;
  background: #123f22;
}

.button-text {
  color: #d8ff8a;
  font-size: 11px;
  line-height: 14px;
  font-weight: 700;
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
