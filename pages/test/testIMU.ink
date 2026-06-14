<script def>
{
  "navigationBarTitleText": "IMU 测试"
}
</script>

<script setup>
const MAX_LOGS = 6;
const SENSOR_FREQUENCY = 60;
const RESET_DEGREES = 8;
// 当前位置阈值，单位是“度”。
// 它判断头部当前已经相对初始位置偏到了哪个方向。
const ANGLE_TRIGGER_DEGREES = {
  left: 10,
  right: 10,
  up: 10,
  down: 5
};

// 目前这个字段只用于反方向解锁保护，不参与 getAction() 的主识别判断。
// 例如右转后回正时，为了避免误判左转，代码会检查是否真的已经进入左侧：
const SPEED_TRIGGER_DEGREES = {
  left: 40,
  right: 40,
  up: 40,
  down: 40
};

// 当前角速度阈值，单位是“度/秒”。
// 它判断你现在是不是正在朝某个方向运动，而且速度够不够。
const SPEED_TRIGGER_DEGREES_PER_SECOND = {
  left: 10,
  right: 10,
  up: 5,
  down: 5
};

const MIN_STABLE_READINGS = 1;
const DEBOUNCE_MS = 450;
const GYRO_NOISE_FLOOR = 0.003;

function radToDeg(value) {
  return value * 180 / Math.PI;
}

function normalizeDegrees(value) {
  let angle = value;

  while (angle > 180) {
    angle -= 360;
  }

  while (angle < -180) {
    angle += 360;
  }

  return angle;
}

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

function getGyroscopeConstructor() {
  if (typeof globalThis !== 'undefined' && globalThis.Gyroscope) {
    return globalThis.Gyroscope;
  }

  if (typeof Gyroscope !== 'undefined') {
    return Gyroscope;
  }

  return null;
}

function getHorizontalAxis(axisDelta) {
  return Math.abs(axisDelta.y) >= Math.abs(axisDelta.z) ? axisDelta.y : axisDelta.z;
}

function getHorizontalSpeed(axisSpeed) {
  return Math.abs(axisSpeed.y) >= Math.abs(axisSpeed.z) ? axisSpeed.y : axisSpeed.z;
}

function getReadableSensorError(event) {
  return event && (event.message || event.error && event.error.message || event.error && event.error.name) || 'IMU 读取失败';
}

function isOppositeSameAxisAction(currentAction, nextAction) {
  return currentAction === 'left' && nextAction === 'right'
    || currentAction === 'right' && nextAction === 'left'
    || currentAction === 'up' && nextAction === 'down'
    || currentAction === 'down' && nextAction === 'up';
}

function isOnActionSide(action, axisDelta) {
  const horizontal = getHorizontalAxis(axisDelta);
  const vertical = axisDelta.x;

  if (action === 'left') {
    return horizontal >= SPEED_TRIGGER_DEGREES.left;
  }

  if (action === 'right') {
    return horizontal <= -SPEED_TRIGGER_DEGREES.right;
  }

  if (action === 'up') {
    return vertical >= SPEED_TRIGGER_DEGREES.up;
  }

  if (action === 'down') {
    return vertical <= -SPEED_TRIGGER_DEGREES.down;
  }

  return false;
}

function getPositionAction(axisDelta) {
  const horizontal = getHorizontalAxis(axisDelta);
  const vertical = axisDelta.x;
  const horizontalAction = horizontal >= 0 ? 'left' : 'right';
  const verticalAction = vertical >= 0 ? 'up' : 'down';
  const horizontalAbs = Math.abs(horizontal);
  const verticalAbs = Math.abs(vertical);
  const horizontalReady = horizontalAbs >= ANGLE_TRIGGER_DEGREES[horizontalAction];
  const verticalReady = verticalAbs >= ANGLE_TRIGGER_DEGREES[verticalAction];

  if (!horizontalReady && !verticalReady) {
    return '';
  }

  if (horizontalReady && verticalReady) {
    const horizontalStrength = horizontalAbs / ANGLE_TRIGGER_DEGREES[horizontalAction];
    const verticalStrength = verticalAbs / ANGLE_TRIGGER_DEGREES[verticalAction];

    return horizontalStrength >= verticalStrength ? horizontalAction : verticalAction;
  }

  return horizontalReady ? horizontalAction : verticalAction;
}

function getFastestSpeedAction(axisSpeed) {
  const safeSpeed = axisSpeed || { x: 0, y: 0, z: 0 };
  const horizontalSpeed = getHorizontalSpeed(safeSpeed);
  const verticalSpeed = safeSpeed.x || 0;
  const horizontalAction = horizontalSpeed >= 0 ? 'left' : 'right';
  const verticalAction = verticalSpeed >= 0 ? 'up' : 'down';
  const horizontalAbs = Math.abs(horizontalSpeed);
  const verticalAbs = Math.abs(verticalSpeed);
  const horizontalReady = horizontalAbs >= SPEED_TRIGGER_DEGREES_PER_SECOND[horizontalAction];
  const verticalReady = verticalAbs >= SPEED_TRIGGER_DEGREES_PER_SECOND[verticalAction];

  if (!horizontalReady && !verticalReady) {
    return '';
  }

  if (horizontalReady && verticalReady) {
    const horizontalStrength = horizontalAbs / SPEED_TRIGGER_DEGREES_PER_SECOND[horizontalAction];
    const verticalStrength = verticalAbs / SPEED_TRIGGER_DEGREES_PER_SECOND[verticalAction];

    return horizontalStrength >= verticalStrength ? horizontalAction : verticalAction;
  }

  return horizontalReady ? horizontalAction : verticalAction;
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
    this.gyroDelta = { x: 0, y: 0, z: 0 };
    this.gyroSpeed = { x: 0, y: 0, z: 0 };
    this.lastGyroTimestamp = null;
    this.pendingAction = '';
    this.pendingCount = 0;
    this.activeAction = '';
    this.lastTriggerAt = 0;
    this.startGyroscopeSensor();
  },
  startGyroscopeSensor() {
    const GyroscopeConstructor = getGyroscopeConstructor();

    this.stopSensor();
    this.gyroDelta = { x: 0, y: 0, z: 0 };
    this.gyroSpeed = { x: 0, y: 0, z: 0 };
    this.lastGyroTimestamp = null;

    if (!GyroscopeConstructor) {
      this.setData({
        statusText: '当前环境不支持 Gyroscope'
      });
      this.pushLog(`${formatTime(new Date())} gyro unavailable`);
      return;
    }

    try {
      this.sensor = new GyroscopeConstructor({ frequency: SENSOR_FREQUENCY });
      this.sensor.addEventListener('activate', () => {
        this.setData({
          statusText: '陀螺仪已启动，请从初始位置转头',
          baseText: 'gyro x 0 / y 0 / z 0'
        });
        this.pushLog(`${formatTime(new Date())} gyro active`);
      });
      this.sensor.addEventListener('reading', () => {
        this.handleGyroReading();
      });
      this.sensor.addEventListener('error', (event) => {
        const message = getReadableSensorError(event);

        this.setData({
          statusText: message
        });
        this.pushLog(`${formatTime(new Date())} gyro error ${message}`);
      });
      this.sensor.start();
    } catch (error) {
      this.setData({
        statusText: error && error.message || 'Gyroscope 启动失败'
      });
    }
  },
  stopSensor() {
    if (this.sensor && typeof this.sensor.stop === 'function') {
      this.sensor.stop();
    }

    this.sensor = null;
  },
  resetBase() {
    this.gyroDelta = { x: 0, y: 0, z: 0 };
    this.gyroSpeed = { x: 0, y: 0, z: 0 };
    this.lastGyroTimestamp = null;
    this.pendingAction = '';
    this.pendingCount = 0;
    this.activeAction = '';
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
  },
  getAction(axisDelta, axisSpeed) {
    const positionAction = getPositionAction(axisDelta);
    const speedAction = getFastestSpeedAction(axisSpeed);

    if (!positionAction || !speedAction || positionAction !== speedAction) {
      return '';
    }

    return positionAction;
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
    const now = Date.now();

    if (!action || this.activeAction === action || now - this.lastTriggerAt < DEBOUNCE_MS) {
      return;
    }

    if (isOppositeSameAxisAction(this.activeAction, action) && !isOnActionSide(action, axisDelta)) {
      return;
    }

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

    this.activeAction = action;
    this.lastTriggerAt = now;
    this.setData(nextData);
    this.updateActiveClass(action);
    this.pushLog(`${formatTime(new Date())} ${this.getActionText(action)} x=${formatNumber(axisDelta.x)} y=${formatNumber(axisDelta.y)} z=${formatNumber(axisDelta.z)}`);
  },
  handleAxisDelta(axisDelta, axisSpeed) {
    const nextAction = this.getAction(axisDelta, axisSpeed);
    const horizontal = getHorizontalAxis(axisDelta);

    if (Math.abs(axisDelta.x) < RESET_DEGREES && Math.abs(horizontal) < RESET_DEGREES) {
      this.activeAction = '';
      this.pendingAction = '';
      this.pendingCount = 0;
      this.updateActiveClass('');
      this.setData({
        statusText: '陀螺仪已回中，等待头动',
        actionText: '未触发'
      });
    } else if (nextAction) {
      if (this.pendingAction === nextAction) {
        this.pendingCount += 1;
      } else {
        this.pendingAction = nextAction;
        this.pendingCount = 1;
      }

      if (this.pendingCount >= MIN_STABLE_READINGS) {
        this.triggerAction(nextAction, axisDelta);
      }
    }

    this.setData({
      xText: formatNumber(axisDelta.x),
      yText: formatNumber(axisDelta.y),
      zText: formatNumber(axisDelta.z),
      speedText: axisSpeed ? `x ${formatNumber(axisSpeed.x)} / y ${formatNumber(axisSpeed.y)} / z ${formatNumber(axisSpeed.z)}` : '-'
    });
  },
  handleGyroReading() {
    const sensor = this.sensor;

    if (!sensor) {
      return;
    }

    const timestamp = sensor.timestamp || Date.now();

    if (this.lastGyroTimestamp === null) {
      this.lastGyroTimestamp = timestamp;
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

    let dt = timestamp - this.lastGyroTimestamp;

    if (dt > 1) {
      dt = dt / 1000;
    }

    dt = Math.max(0, Math.min(dt, 0.08));
    this.lastGyroTimestamp = timestamp;

    const x = Math.abs(sensor.x || 0) < GYRO_NOISE_FLOOR ? 0 : sensor.x || 0;
    const y = Math.abs(sensor.y || 0) < GYRO_NOISE_FLOOR ? 0 : sensor.y || 0;
    const z = Math.abs(sensor.z || 0) < GYRO_NOISE_FLOOR ? 0 : sensor.z || 0;

    this.gyroDelta = {
      x: normalizeDegrees(this.gyroDelta.x + radToDeg(x * dt)),
      y: normalizeDegrees(this.gyroDelta.y + radToDeg(y * dt)),
      z: normalizeDegrees(this.gyroDelta.z + radToDeg(z * dt))
    };
    this.gyroSpeed = {
      x: radToDeg(x),
      y: radToDeg(y),
      z: radToDeg(z)
    };

    this.handleAxisDelta(this.gyroDelta, this.gyroSpeed);
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
