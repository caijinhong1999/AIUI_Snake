<script def>
{
  "navigationBarTitleText": "传统模式"
}
</script>

<script setup>
import wx from 'wx';

const GRID_WIDTH = 50;
const GRID_HEIGHT = 18;
const MIN_PLAY_X = 0;
const MAX_PLAY_X = GRID_WIDTH - 1;
const MIN_PLAY_Y = 0;
const MAX_PLAY_Y = GRID_HEIGHT - 1;
const INITIAL_SNAKE = [
  { x: 24, y: 9 },
  { x: 23, y: 9 },
  { x: 22, y: 9 }
];
const DIRECTIONS = {
  up: { x: 0, y: -1 },
  down: { x: 0, y: 1 },
  left: { x: -1, y: 0 },
  right: { x: 1, y: 0 }
};
const OPPOSITE = {
  up: 'down',
  down: 'up',
  left: 'right',
  right: 'left'
};
const SENSOR_FREQUENCY = 60;
const TURN_COOLDOWN = 240;
const ORIENTATION_THRESHOLD = 0.18;
const ORIENTATION_NEUTRAL_THRESHOLD = 0.07;
const GYRO_THRESHOLD = 0.75;
const ACCEL_THRESHOLD = 2.4;
const INITIAL_SPEED = 460;
const MIN_SPEED = 220;
const SPEED_STEP = 25;
const APPLE_TARGET = 10;
const DOUBLE_TAP_MS = 450;
const LEFT_TURN = {
  up: 'left',
  left: 'down',
  down: 'right',
  right: 'up'
};
const RIGHT_TURN = {
  up: 'right',
  right: 'down',
  down: 'left',
  left: 'up'
};

function sameCell(a, b) {
  return a.x === b.x && a.y === b.y;
}

function isInsideGrid(cell) {
  return cell.x >= 0 && cell.x < GRID_WIDTH && cell.y >= 0 && cell.y < GRID_HEIGHT;
}

function buildBoardLines(snake, food) {
  const lines = [];

  for (let y = 0; y < GRID_HEIGHT; y += 1) {
    let text = '';

    for (let x = 0; x < GRID_WIDTH; x += 1) {
      let symbol = ' ';

      if (sameCell(food, { x, y })) {
        symbol = '*';
      }

      for (let index = 0; index < snake.length; index += 1) {
        if (sameCell(snake[index], { x, y })) {
          symbol = index === 0 ? '@' : 'O';
          break;
        }
      }

      text += symbol;
    }

    lines.push(text);
  }

  return lines;
}

function buildBoardData(snake, food) {
  const lines = buildBoardLines(snake, food);

  return {
    boardLine0: lines[0],
    boardLine1: lines[1],
    boardLine2: lines[2],
    boardLine3: lines[3],
    boardLine4: lines[4],
    boardLine5: lines[5],
    boardLine6: lines[6],
    boardLine7: lines[7],
    boardLine8: lines[8],
    boardLine9: lines[9],
    boardLine10: lines[10],
    boardLine11: lines[11],
    boardLine12: lines[12],
    boardLine13: lines[13],
    boardLine14: lines[14],
    boardLine15: lines[15],
    boardLine16: lines[16],
    boardLine17: lines[17]
  };
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function normalizeAngle(angle) {
  let normalized = angle;

  while (normalized > Math.PI) {
    normalized -= Math.PI * 2;
  }

  while (normalized < -Math.PI) {
    normalized += Math.PI * 2;
  }

  return normalized;
}

function quaternionToEuler(quaternion) {
  const x = quaternion[0];
  const y = quaternion[1];
  const z = quaternion[2];
  const w = quaternion[3];
  const sinRoll = 2 * (w * x + y * z);
  const cosRoll = 1 - 2 * (x * x + y * y);
  const roll = Math.atan2(sinRoll, cosRoll);
  const sinPitch = 2 * (w * y - z * x);
  const pitch = Math.asin(clamp(sinPitch, -1, 1));
  const sinYaw = 2 * (w * z + x * y);
  const cosYaw = 1 - 2 * (y * y + z * z);
  const yaw = Math.atan2(sinYaw, cosYaw);

  return {
    roll,
    pitch,
    yaw
  };
}

export default {
  data: {
    boardLine0: '',
    boardLine1: '',
    boardLine2: '',
    boardLine3: '',
    boardLine4: '',
    boardLine5: '',
    boardLine6: '',
    boardLine7: '',
    boardLine8: '',
    boardLine9: '',
    boardLine10: '',
    boardLine11: '',
    boardLine12: '',
    boardLine13: '',
    boardLine14: '',
    boardLine15: '',
    boardLine16: '',
    boardLine17: '',
    snake: [],
    food: { x: 12, y: 9 },
    direction: 'right',
    pendingDirection: 'right',
    score: 0,
    applesEaten: 0,
    speed: INITIAL_SPEED,
    status: 'playing',
    statusText: '传统模式',
    resultMessage: '',
    resultClass: '',
    imuText: 'IMU 未启动',
    lastGyroMoveAt: 0
  },
  onLoad() {
    this.restartGame();
  },
  onUnload() {
    this.stopGameLoop();
    this.stopMotionSensors();
  },
  onHide() {
    this.stopGameLoop();
    this.stopMotionSensors();
  },
  restartGame() {
    const snake = INITIAL_SNAKE.map((cell) => ({ ...cell }));
    const food = this.createFood(snake);

    this.stopGameLoop();
    this.stopMotionSensors();
    this.setData({
      snake,
      food,
      direction: 'right',
      pendingDirection: 'right',
      score: 0,
      applesEaten: 0,
      speed: INITIAL_SPEED,
      status: 'playing',
      statusText: '传统模式',
      resultMessage: '',
      resultClass: '',
      lastGyroMoveAt: 0
    });
    this.setData(buildBoardData(snake, food));

    this.startMotionSensors();
    this.startGameLoop();
  },
  startGameLoop() {
    this.stopGameLoop();
    this.gameTimer = setInterval(() => {
      this.tick();
    }, this.data.speed);
  },
  stopGameLoop() {
    if (this.gameTimer) {
      clearInterval(this.gameTimer);
    }

    this.gameTimer = null;
  },
  tick() {
    if (this.data.status !== 'playing') {
      return;
    }

    const direction = this.data.pendingDirection;
    const vector = DIRECTIONS[direction];
    const snake = this.data.snake.map((cell) => ({ ...cell }));
    const head = {
      x: snake[0].x + vector.x,
      y: snake[0].y + vector.y
    };
    if (this.isWallCollision(head)) {
      this.endGame();
      return;
    }

    const willEat = sameCell(head, this.data.food);
    const nextSnake = [head].concat(snake);
    let food = this.data.food;
    let score = this.data.score;
    let applesEaten = this.data.applesEaten;
    const previousSpeed = this.data.speed;
    let speed = this.data.speed;

    if (willEat) {
      score += 10;
      applesEaten += 1;
      food = this.createFood(nextSnake);

      if (score % 50 === 0 && speed > MIN_SPEED) {
        speed = Math.max(MIN_SPEED, speed - SPEED_STEP);
      }
    }

    if (!willEat) {
      nextSnake.pop();
    }

    if (this.isSelfCollision(head, nextSnake.slice(1))) {
      this.setData({
        snake: nextSnake,
        direction
      });
      this.setData(buildBoardData(nextSnake, food));
      this.endGame(nextSnake, food);
      return;
    }

    this.setData({
      snake: nextSnake,
      food,
      score,
      applesEaten,
      speed,
      direction
    });
    this.setData(buildBoardData(nextSnake, food));

    if (applesEaten >= APPLE_TARGET) {
      this.completeGame();
      return;
    }

    if (speed !== previousSpeed) {
      this.startGameLoop();
    }
  },
  endGame(finalSnake, finalFood) {
    this.stopGameLoop();
    this.stopMotionSensors();
    const snake = finalSnake || this.data.snake;
    const food = finalFood || this.data.food;

    this.setData({
      status: 'ended',
      statusText: '传统模式',
      resultMessage: 'Game Over!',
      resultClass: 'game-over'
    });
    this.setData(buildBoardData(snake, food));
  },
  completeGame() {
    this.stopGameLoop();
    this.stopMotionSensors();
    this.setData({
      status: 'won',
      statusText: '传统模式',
      resultMessage: 'Congratulations!',
      resultClass: 'success'
    });
  },
  createFood(snake) {
    const emptyCells = [];

    for (let y = MIN_PLAY_Y; y <= MAX_PLAY_Y; y += 1) {
      for (let x = MIN_PLAY_X; x <= MAX_PLAY_X; x += 1) {
        const cell = { x, y };
        const occupied = snake.some((part) => sameCell(part, cell));

        if (!occupied) {
          emptyCells.push(cell);
        }
      }
    }

    return emptyCells[Math.floor(Math.random() * emptyCells.length)] || { x: 0, y: 0 };
  },
  isWallCollision(head) {
    return !isInsideGrid(head);
  },
  isSelfCollision(head, snake) {
    return snake.some((part) => sameCell(part, head));
  },
  requestDirection(nextDirection) {
    if (!DIRECTIONS[nextDirection]) {
      return false;
    }

    if (OPPOSITE[this.data.direction] === nextDirection) {
      return false;
    }

    this.setData({
      pendingDirection: nextDirection
    });

    return true;
  },
  turnLeft() {
    const baseDirection = this.data.pendingDirection || this.data.direction;
    return this.requestDirection(LEFT_TURN[baseDirection]);
  },
  turnRight() {
    const baseDirection = this.data.pendingDirection || this.data.direction;
    return this.requestDirection(RIGHT_TURN[baseDirection]);
  },
  startMotionSensors() {
    this.stopMotionSensors();
    this.motionSensors = [];
    this.orientationBase = null;
    this.orientationLock = {
      horizontal: false,
      vertical: false
    };
    this.activeSensorNames = [];
    this.failedSensorNames = [];
    this.startAbsoluteOrientationSensor();
    this.startGyroscopeSensor();
    this.startAccelerometerSensor();
    this.updateImuText();
  },
  stopMotionSensors() {
    if (this.motionSensors) {
      this.motionSensors.forEach((sensor) => {
        if (sensor && typeof sensor.stop === 'function') {
          sensor.stop();
        }
      });
    }

    this.motionSensors = [];
    this.orientationBase = null;
    this.orientationLock = null;
  },
  startAbsoluteOrientationSensor() {
    if (typeof AbsoluteOrientationSensor !== 'function') {
      this.failedSensorNames.push('方向');
      return;
    }

    this.createMotionSensor({
      name: '方向',
      SensorClass: AbsoluteOrientationSensor,
      onReading: (sensor) => this.handleOrientationReading(sensor)
    });
  },
  startGyroscopeSensor() {
    if (typeof Gyroscope !== 'function') {
      this.failedSensorNames.push('陀螺仪');
      return;
    }

    this.createMotionSensor({
      name: '陀螺仪',
      SensorClass: Gyroscope,
      onReading: (sensor) => this.handleGyroscopeReading(sensor)
    });
  },
  startAccelerometerSensor() {
    if (typeof Accelerometer !== 'function') {
      this.failedSensorNames.push('加速度');
      return;
    }

    this.createMotionSensor({
      name: '加速度',
      SensorClass: Accelerometer,
      onReading: (sensor) => this.handleAccelerometerReading(sensor)
    });
  },
  createMotionSensor(options) {
    let sensor = null;

    try {
      sensor = new options.SensorClass({ frequency: SENSOR_FREQUENCY });
    } catch (error) {
      this.noteSensorFailure(options.name, error.message || '创建失败');
      return;
    }

    sensor.addEventListener('activate', () => {
      if (this.activeSensorNames.indexOf(options.name) === -1) {
        this.activeSensorNames.push(options.name);
      }

      this.updateImuText();
    });

    sensor.addEventListener('reading', () => {
      options.onReading(sensor);
    });

    sensor.addEventListener('error', (event) => {
      const message = event && (event.message || event.error) ? event.message || event.error : '不可用';
      this.noteSensorFailure(options.name, message);
    });

    try {
      sensor.start();
      this.motionSensors.push(sensor);
    } catch (error) {
      this.noteSensorFailure(options.name, error.message || '启动失败');
    }
  },
  noteSensorFailure(name, message) {
    if (this.failedSensorNames.indexOf(name) === -1) {
      this.failedSensorNames.push(name);
    }

    this.setData({
      imuText: `${name}${message}，按键可调试`
    });
  },
  updateImuText() {
    if (this.activeSensorNames.length > 0) {
      this.setData({
        imuText: `IMU ${this.activeSensorNames.join('/')}已启动`
      });
      return;
    }

    if (this.failedSensorNames.length > 0) {
      this.setData({
        imuText: `IMU ${this.failedSensorNames.join('/')}不可用，按键可调试`
      });
      return;
    }

    this.setData({
      imuText: 'IMU 检测中，按键可调试'
    });
  },
  applyMotionDirection(nextDirection, source) {
    const now = Date.now();

    if (now - this.data.lastGyroMoveAt < TURN_COOLDOWN) {
      return;
    }

    if (!nextDirection) {
      return;
    }

    if (!this.requestDirection(nextDirection)) {
      return;
    }

    this.setData({
      lastGyroMoveAt: now,
      imuText: `${source} ${nextDirection}`
    });

    return true;
  },
  handleOrientationReading(sensor) {
    const quaternion = sensor.quaternion;

    if (!quaternion || quaternion.length !== 4) {
      return;
    }

    const euler = quaternionToEuler(quaternion);

    if (!this.orientationBase) {
      this.orientationBase = euler;
      return;
    }

    const yawDelta = normalizeAngle(euler.yaw - this.orientationBase.yaw);
    const pitchDelta = normalizeAngle(euler.pitch - this.orientationBase.pitch);
    const lock = this.orientationLock || {
      horizontal: false,
      vertical: false
    };
    let nextDirection = '';

    if (Math.abs(yawDelta) < ORIENTATION_NEUTRAL_THRESHOLD) {
      lock.horizontal = false;
    }

    if (Math.abs(pitchDelta) < ORIENTATION_NEUTRAL_THRESHOLD) {
      lock.vertical = false;
    }

    if (!lock.horizontal && Math.abs(yawDelta) > Math.abs(pitchDelta) && Math.abs(yawDelta) > ORIENTATION_THRESHOLD) {
      nextDirection = yawDelta > 0 ? 'right' : 'left';
    } else if (!lock.vertical && Math.abs(pitchDelta) > ORIENTATION_THRESHOLD) {
      nextDirection = pitchDelta > 0 ? 'down' : 'up';
    }

    this.orientationLock = lock;
    if (this.applyMotionDirection(nextDirection, '方向')) {
      if (nextDirection === 'left' || nextDirection === 'right') {
        lock.horizontal = true;
      } else if (nextDirection === 'up' || nextDirection === 'down') {
        lock.vertical = true;
      }

      this.orientationLock = lock;
    }
  },
  handleGyroscopeReading(sensor) {
    if (this.activeSensorNames && this.activeSensorNames.indexOf('方向') !== -1) {
      return;
    }

    const x = sensor.x || 0;
    const y = sensor.y || 0;
    const z = sensor.z || 0;
    const absX = Math.abs(x);
    const absY = Math.abs(y);
    const absZ = Math.abs(z);
    let nextDirection = '';

    if (absZ >= absX && absZ >= absY && absZ > GYRO_THRESHOLD) {
      nextDirection = z > 0 ? 'right' : 'left';
    } else if (absX >= absY && absX > GYRO_THRESHOLD) {
      nextDirection = x > 0 ? 'down' : 'up';
    } else if (absY > GYRO_THRESHOLD) {
      nextDirection = y > 0 ? 'right' : 'left';
    }

    this.applyMotionDirection(nextDirection, '陀螺仪');
  },
  handleAccelerometerReading(sensor) {
    if (this.activeSensorNames && this.activeSensorNames.indexOf('方向') !== -1) {
      return;
    }

    const x = sensor.x || 0;
    const y = sensor.y || 0;
    let nextDirection = '';

    if (Math.abs(x) > Math.abs(y) && Math.abs(x) > ACCEL_THRESHOLD) {
      nextDirection = x > 0 ? 'right' : 'left';
    } else if (Math.abs(y) > ACCEL_THRESHOLD) {
      nextDirection = y > 0 ? 'down' : 'up';
    }

    this.applyMotionDirection(nextDirection, '加速度');
  },
  getKeyCode(event) {
    return event && (event.code || event.key || event.keyCode || event.detail && (event.detail.code || event.detail.key || event.detail.keyCode));
  },
  preventDefault(event) {
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault();
    }
  },
  isConfirmKey(code) {
    return code === 'GlobalHook'
      || code === 'Enter'
      || code === 'NumpadEnter'
      || code === 'Space'
      || code === ' '
      || code === 13
      || code === 32;
  },
  navigateToMenu() {
    this.stopGameLoop();
    this.stopMotionSensors();

    if (wx && typeof wx.redirectTo === 'function') {
      wx.redirectTo({
        url: '/pages/index/index'
      });
      return;
    }

    if (wx && typeof wx.navigateBack === 'function') {
      wx.navigateBack();
    }
  },
  normalizeDirectionKey(code) {
    const keyMap = {
      ArrowUp: 'up',
      Up: 'up',
      KeyW: 'up',
      w: 'up',
      W: 'up',
      38: 'up',
      ArrowDown: 'down',
      Down: 'down',
      KeyS: 'down',
      s: 'down',
      S: 'down',
      40: 'down',
      ArrowLeft: 'left',
      Left: 'left',
      KeyA: 'left',
      a: 'left',
      A: 'left',
      37: 'left',
      ArrowRight: 'right',
      Right: 'right',
      KeyD: 'right',
      d: 'right',
      D: 'right',
      39: 'right'
    };

    return keyMap[code];
  },
  normalizeSlideKey(code) {
    const slideMap = {
      ArrowUp: 'forward',
      Up: 'forward',
      KeyW: 'forward',
      w: 'forward',
      W: 'forward',
      38: 'forward',
      ArrowDown: 'backward',
      Down: 'backward',
      KeyS: 'backward',
      s: 'backward',
      S: 'backward',
      40: 'backward'
    };

    return slideMap[code];
  },
  shouldSkipDuplicateKey(code) {
    const now = Date.now();

    if (this.lastHandledKey === code && now - this.lastHandledKeyAt < 80) {
      return true;
    }

    this.lastHandledKey = code;
    this.lastHandledKeyAt = now;
    return false;
  },
  handleKeyEvent(event, phase) {
    const code = this.getKeyCode(event);
    const slide = this.normalizeSlideKey(code);
    const direction = this.normalizeDirectionKey(code);

    if (this.isConfirmKey(code)) {
      this.preventDefault(event);
      if (phase === 'down') {
        return;
      }
      this.handlePanelConfirm();
      return;
    }

    if (this.shouldSkipDuplicateKey(code)) {
      return;
    }

    if (slide === 'forward') {
      this.preventDefault(event);
      this.turnLeft();
      return;
    }

    if (slide === 'backward') {
      this.preventDefault(event);
      this.turnRight();
      return;
    }

    if (direction) {
      this.preventDefault(event);
      this.requestDirection(direction);
      return;
    }

  },
  handlePanelConfirm() {
    const now = Date.now();

    if (this.lastPanelConfirmAt && now - this.lastPanelConfirmAt <= DOUBLE_TAP_MS) {
      this.lastPanelConfirmAt = 0;
      this.navigateToMenu();
      return;
    }

    this.lastPanelConfirmAt = now;
  },
  onKeyDown(event) {
    this.handleKeyEvent(event, 'down');
  },
  onKeyUp(event) {
    this.handleKeyEvent(event, 'up');
  }
}
</script>

<page>
  <view class="game">
    <view class="hud">
      <view class="hud-main">
        <text class="imu">{{ imuText }}</text>
      </view>
      <view class="hud-side">
        <text class="hud-score">{{ score }}</text>
      </view>
    </view>

    <view class="board">
      <text class="board-text">{{ boardLine0 }}</text>
      <text class="board-text">{{ boardLine1 }}</text>
      <text class="board-text">{{ boardLine2 }}</text>
      <text class="board-text">{{ boardLine3 }}</text>
      <text class="board-text">{{ boardLine4 }}</text>
      <text class="board-text">{{ boardLine5 }}</text>
      <text class="board-text">{{ boardLine6 }}</text>
      <text class="board-text">{{ boardLine7 }}</text>
      <text class="board-text">{{ boardLine8 }}</text>
      <text class="board-text">{{ boardLine9 }}</text>
      <text class="board-text">{{ boardLine10 }}</text>
      <text class="board-text">{{ boardLine11 }}</text>
      <text class="board-text">{{ boardLine12 }}</text>
      <text class="board-text">{{ boardLine13 }}</text>
      <text class="board-text">{{ boardLine14 }}</text>
      <text class="board-text">{{ boardLine15 }}</text>
      <text class="board-text">{{ boardLine16 }}</text>
      <text class="board-text">{{ boardLine17 }}</text>
    </view>

    <view wx:if="{{ resultMessage }}" class="result-mask">
      <text class="result-text {{ resultClass }}">{{ resultMessage }}</text>
    </view>
  </view>
</page>

<style>
.game {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  position: relative;
  box-sizing: border-box;
  width: 100%;
  height: 100vh;
  padding: 10px 18px;
  background: #062414;
  color: #caff8d;
}

.hud {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  position: relative;
  width: 100%;
  max-width: 500px;
  min-height: 34px;
  margin-bottom: 4px;
}

.hud-main,
.hud-side {
  display: flex;
  flex-direction: column;
}

.hud-main {
  width: 400px;
  flex: 1;
  min-width: 0;
  align-items: flex-start;
  text-align: left;
}

.hud-side {
  position: absolute;
  top: 0;
  right: 0;
  width: 70px;
  flex: 0 0 70px;
  align-items: flex-end;
  text-align: right;
  white-space: nowrap;
}

.hud-label,
.status,
.imu {
  color: #8ee05f;
  font-size: 12px;
  line-height: 14px;
}

.imu {
  max-height: 28px;
  padding-right: 76px;
  overflow: hidden;
}

.hud-score {
  color: #e7ff8f;
  font-size: 34px;
  line-height: 36px;
  font-weight: 700;
  text-align: right;
}

.board {
  display: flex;
  flex-direction: column;
  justify-content: center;
  width: 450px;
  height: 300px;
  padding: 8px;
  border: 5px solid #75f05c;
  background: #061907;
  box-sizing: border-box;
}

.board-text {
  display: block;
  width: 100%;
  color: #8cff55;
  font-family: Consolas, Monaco, "Courier New", monospace;
  font-size: 16px;
  line-height: 16px;
  letter-spacing: 0;
  text-align: center;
  white-space: pre;
}

.result-mask {
  position: absolute;
  left: 0;
  top: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

.result-text {
  color: #e7ff8f;
  font-size: 42px;
  line-height: 50px;
  font-weight: 700;
  text-align: center;
}

.result-text.game-over {
  color: #8cff55;
}

.result-text.success {
  color: #e7ff8f;
}

</style>
