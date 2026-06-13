<script def>
{
  "navigationBarTitleText": "传统模式"
}
</script>

<script setup>
import wx from 'wx';

const GRID_SIZE = 18;
const INITIAL_SNAKE = [
  { x: 8, y: 9 },
  { x: 7, y: 9 },
  { x: 6, y: 9 }
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

function sameCell(a, b) {
  return a.x === b.x && a.y === b.y;
}

function buildBoardLines(snake, food) {
  const lines = [];

  for (let y = 0; y < GRID_SIZE; y += 1) {
    let text = '';

    for (let x = 0; x < GRID_SIZE; x += 1) {
      let symbol = '　';

      if (sameCell(food, { x, y })) {
        symbol = '◆';
      }

      for (let index = 0; index < snake.length; index += 1) {
        if (sameCell(snake[index], { x, y })) {
          symbol = index === 0 ? '●' : '■';
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
    speed: 260,
    status: 'playing',
    statusText: '传统模式',
    imuText: 'IMU 未启动',
    lastGyroMoveAt: 0
  },
  onLoad() {
    this.restartGame();
  },
  onUnload() {
    this.stopGameLoop();
    this.stopGyroscope();
  },
  onHide() {
    this.stopGameLoop();
    this.stopGyroscope();
  },
  restartGame() {
    const snake = INITIAL_SNAKE.map((cell) => ({ ...cell }));
    const food = this.createFood(snake);

    this.stopGameLoop();
    this.stopGyroscope();
    this.setData({
      snake,
      food,
      direction: 'right',
      pendingDirection: 'right',
      score: 0,
      speed: 260,
      status: 'playing',
      statusText: '传统模式',
      lastGyroMoveAt: 0
    });
    this.setData(buildBoardData(snake, food));

    this.startGyroscope();
    this.startGameLoop();
  },
  backHome() {
    this.stopGameLoop();
    this.stopGyroscope();

    if (wx && typeof wx.navigateBack === 'function') {
      wx.navigateBack();
    }
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
    const willEat = sameCell(head, this.data.food);
    const collisionBody = willEat ? snake : snake.slice(0, -1);

    if (this.isWallCollision(head) || this.isSelfCollision(head, collisionBody)) {
      this.endGame();
      return;
    }

    snake.unshift(head);
    let food = this.data.food;
    let score = this.data.score;
    const previousSpeed = this.data.speed;
    let speed = this.data.speed;

    if (willEat) {
      score += 10;
      food = this.createFood(snake);

      if (score % 50 === 0 && speed > 120) {
        speed -= 20;
      }
    }

    if (!willEat) {
      snake.pop();
    }

    this.setData({
      snake,
      food,
      score,
      speed,
      direction
    });
    this.setData(buildBoardData(snake, food));

    if (speed !== previousSpeed) {
      this.startGameLoop();
    }
  },
  endGame() {
    this.stopGameLoop();
    this.setData({
      status: 'ended',
      statusText: '游戏结束：撞到墙或自己'
    });
    this.setData(buildBoardData(this.data.snake, this.data.food));
  },
  createFood(snake) {
    const emptyCells = [];

    for (let y = 0; y < GRID_SIZE; y += 1) {
      for (let x = 0; x < GRID_SIZE; x += 1) {
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
    return head.x < 0 || head.x >= GRID_SIZE || head.y < 0 || head.y >= GRID_SIZE;
  },
  isSelfCollision(head, snake) {
    return snake.some((part) => sameCell(part, head));
  },
  requestDirection(nextDirection) {
    if (!DIRECTIONS[nextDirection]) {
      return;
    }

    if (OPPOSITE[this.data.direction] === nextDirection) {
      return;
    }

    this.setData({
      pendingDirection: nextDirection
    });
  },
  startGyroscope() {
    if (typeof Gyroscope !== 'function') {
      this.setData({
        imuText: '未检测到 Gyroscope，方向键可调试'
      });
      return;
    }

    const gyro = new Gyroscope({ frequency: 60 });

    gyro.addEventListener('activate', () => {
      this.setData({
        imuText: 'IMU 已启动'
      });
    });

    gyro.addEventListener('reading', () => {
      this.handleGyroscopeReading(gyro);
    });

    gyro.addEventListener('error', (event) => {
      const message = event && (event.message || event.error) ? event.message || event.error : '读取失败';
      this.setData({
        imuText: `IMU ${message}`
      });
    });

    try {
      gyro.start();
      this.gyroSensor = gyro;
    } catch (error) {
      this.setData({
        imuText: `IMU ${error.message || '启动失败'}`
      });
    }
  },
  stopGyroscope() {
    if (this.gyroSensor && typeof this.gyroSensor.stop === 'function') {
      this.gyroSensor.stop();
    }

    this.gyroSensor = null;
  },
  handleGyroscopeReading(sensor) {
    const now = Date.now();

    if (now - this.data.lastGyroMoveAt < 220) {
      return;
    }

    const x = sensor.x || 0;
    const y = sensor.y || 0;
    const threshold = 0.85;
    let nextDirection = '';

    if (Math.abs(y) > Math.abs(x) && Math.abs(y) > threshold) {
      nextDirection = y > 0 ? 'right' : 'left';
    } else if (Math.abs(x) > threshold) {
      nextDirection = x > 0 ? 'down' : 'up';
    }

    if (nextDirection) {
      this.requestDirection(nextDirection);
      this.setData({
        lastGyroMoveAt: now,
        imuText: `IMU ${nextDirection}`
      });
    }
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
  shouldSkipDuplicateKey(code) {
    const now = Date.now();

    if (this.lastHandledKey === code && now - this.lastHandledKeyAt < 80) {
      return true;
    }

    this.lastHandledKey = code;
    this.lastHandledKeyAt = now;
    return false;
  },
  handleKeyEvent(event) {
    const code = this.getKeyCode(event);
    const direction = this.normalizeDirectionKey(code);

    if (this.shouldSkipDuplicateKey(code)) {
      return;
    }

    if (direction) {
      this.preventDefault(event);
      this.requestDirection(direction);
      return;
    }

    if (this.isConfirmKey(code) && this.data.status === 'ended') {
      this.preventDefault(event);
      this.restartGame();
    }
  },
  onKeyDown(event) {
    this.handleKeyEvent(event);
  },
  onKeyUp(event) {
    this.handleKeyEvent(event);
  }
}
</script>

<page>
  <view class="game">
    <view class="hud">
      <view class="hud-main">
        <text class="hud-label">传统模式</text>
        <text class="hud-score">{{ score }}</text>
      </view>
      <view class="hud-side">
        <text class="status">{{ statusText }}</text>
        <text class="imu">{{ imuText }}</text>
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

    <view class="actions">
      <button class="small-button" bindtap="backHome">返回</button>
      <button class="small-button primary" bindtap="restartGame">重开</button>
    </view>
  </view>
</page>

<style>
.game {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: flex-start;
  box-sizing: border-box;
  width: 100%;
  height: 100vh;
  padding: 16px 18px;
  background: #062414;
  color: #caff8d;
}

.hud {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  width: 100%;
  max-width: 420px;
  margin-bottom: 12px;
}

.hud-main,
.hud-side {
  display: flex;
  flex-direction: column;
}

.hud-side {
  align-items: flex-end;
}

.hud-label,
.status,
.imu {
  color: #8ee05f;
  font-size: 12px;
  line-height: 16px;
}

.hud-score {
  color: #e7ff8f;
  font-size: 34px;
  line-height: 38px;
  font-weight: 700;
}

.board {
  display: flex;
  flex-direction: column;
  width: 324px;
  height: 324px;
  justify-content: center;
  padding: 12px;
  border: 3px solid #75f05c;
  background: #061907;
  box-sizing: border-box;
}

.board-text {
  display: block;
  width: 100%;
  color: #8cff55;
  font-family: monospace;
  font-size: 15px;
  line-height: 16px;
  letter-spacing: 0;
  text-align: center;
}

.actions {
  display: flex;
  gap: 12px;
  width: 324px;
  margin-top: 14px;
}

.small-button {
  flex: 1;
  height: 42px;
  color: #caff8d;
  border: 2px solid #3c9148;
  border-radius: 8px;
  background: #0d351e;
  font-size: 16px;
  line-height: 22px;
  text-align: center;
  box-sizing: border-box;
}

.small-button.primary {
  border-color: #72ff62;
  color: #e7ff8f;
}
</style>
