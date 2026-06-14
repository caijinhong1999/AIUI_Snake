import Tools from '../Tools/tools.js';

const GRID_WIDTH = 44;
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
const INITIAL_SPEED = 320;
const MIN_SPEED = 140;
const SPEED_STEP = 30;
const APPLE_TARGET = 10;
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
const OPPOSITE_DIRECTION = {
  up: 'down',
  down: 'up',
  left: 'right',
  right: 'left'
};
const DIRECTION_TEXT = {
  up: '向上',
  down: '向下',
  left: '向左',
  right: '向右'
};

function sameCell(a, b) {
  return a.x === b.x && a.y === b.y;
}

function isInsideGrid(cell) {
  return cell.x >= 0 && cell.x < GRID_WIDTH && cell.y >= 0 && cell.y < GRID_HEIGHT;
}

function wrapCell(cell) {
  return {
    x: (cell.x + GRID_WIDTH) % GRID_WIDTH,
    y: (cell.y + GRID_HEIGHT) % GRID_HEIGHT
  };
}

function buildBoardLines(snake, food) {
  const lines = [];

  for (let y = 0; y < GRID_HEIGHT; y += 1) {
    let text = '';

    for (let x = 0; x < GRID_WIDTH; x += 1) {
      let symbol = '.';

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

function getInitialGameData(statusText) {
  return {
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
    statusText,
    resultMessage: '',
    resultClass: '',
    controlHint: '等待前滑或后滑'
  };
}

export function createSnakeGamePage(options) {
  const pageOptions = options || {};
  const statusText = pageOptions.statusText || '传统模式';
  const wrapWalls = pageOptions.wrapWalls === true;

  return {
    data: getInitialGameData(statusText),
    onLoad() {
      this.restartGame();
      this.startHeadDirectionControl();
    },
    onUnload() {
      this.stopGameLoop();
      this.stopHeadDirectionControl();
    },
    onHide() {
      this.stopGameLoop();
      this.stopHeadDirectionControl();
    },
    restartGame() {
      const snake = INITIAL_SNAKE.map((cell) => ({ ...cell }));
      const food = this.createFood(snake);

      this.stopGameLoop();
      this.currentDirection = 'right';
      this.nextDirection = 'right';
      this.setData({
        snake,
        food,
        direction: 'right',
        pendingDirection: 'right',
        score: 0,
        applesEaten: 0,
        speed: INITIAL_SPEED,
        status: 'playing',
        statusText,
        resultMessage: '',
        resultClass: '',
        controlHint: '等待前滑或后滑'
      });
      this.setData(buildBoardData(snake, food));

      if (this.headTracker) {
        this.headTracker.reset();
      }

      this.startGameLoop();
    },
    startGameLoop(nextSpeed) {
      this.stopGameLoop();
      this.gameTimer = setInterval(() => {
        this.tick();
      }, nextSpeed || this.data.speed);
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

      const direction = this.nextDirection || this.data.pendingDirection || this.data.direction;
      const vector = DIRECTIONS[direction];
      const snake = this.data.snake.map((cell) => ({ ...cell }));
      const nextHead = {
        x: snake[0].x + vector.x,
        y: snake[0].y + vector.y
      };
      const head = wrapWalls ? wrapCell(nextHead) : nextHead;

      if (!wrapWalls && this.isWallCollision(head)) {
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

        if (speed > MIN_SPEED) {
          speed = Math.max(MIN_SPEED, speed - SPEED_STEP);
        }
      }

      if (!willEat) {
        nextSnake.pop();
      }

      if (this.isSelfCollision(head, nextSnake.slice(1))) {
        this.setData({
          snake: nextSnake,
          direction,
          pendingDirection: direction
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
        direction,
        pendingDirection: direction
      });
      this.currentDirection = direction;
      this.nextDirection = direction;
      this.setData(buildBoardData(nextSnake, food));

      if (applesEaten >= APPLE_TARGET) {
        this.completeGame();
        return;
      }

      if (speed !== previousSpeed) {
        this.startGameLoop(speed);
      }
    },
    endGame(finalSnake, finalFood) {
      this.stopGameLoop();
      const snake = finalSnake || this.data.snake;
      const food = finalFood || this.data.food;

      this.setData({
        status: 'ended',
        statusText,
        resultMessage: 'Game Over!',
        resultClass: 'game-over'
      });
      this.setData(buildBoardData(snake, food));
    },
    completeGame() {
      this.stopGameLoop();
      this.setData({
        status: 'won',
        statusText,
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
    setDirection(nextDirection) {
      if (!DIRECTIONS[nextDirection]) {
        return false;
      }

      this.currentDirection = this.currentDirection || this.data.direction;
      this.nextDirection = nextDirection;
      this.setData({
        direction: nextDirection,
        pendingDirection: nextDirection
      });

      return true;
    },
    turnLeft() {
      const currentDirection = this.nextDirection || this.currentDirection || this.data.pendingDirection || this.data.direction;
      const nextDirection = LEFT_TURN[currentDirection];

      return this.setDirection(nextDirection);
    },
    turnRight() {
      const currentDirection = this.nextDirection || this.currentDirection || this.data.pendingDirection || this.data.direction;
      const nextDirection = RIGHT_TURN[currentDirection];

      return this.setDirection(nextDirection);
    },
    setAbsoluteDirection(targetDirection) {
      const currentDirection = this.nextDirection || this.currentDirection || this.data.pendingDirection || this.data.direction;

      if (!DIRECTIONS[targetDirection] || targetDirection === currentDirection) {
        return false;
      }

      if (targetDirection === OPPOSITE_DIRECTION[currentDirection]) {
        return false;
      }

      return this.setDirection(targetDirection);
    },
    startHeadDirectionControl() {
      this.stopHeadDirectionControl();
      this.headTracker = Tools.createHeadDirectionTracker({
        onActivate: () => {
          this.setData({
            controlHint: '前后滑动转向，头部绝对方向也可转向。'
          });
        },
        onError: (message) => {
          this.setData({
            controlHint: message
          });
        },
        onAction: (action) => {
          return this.handleHeadDirection(action);
        }
      });
      this.headTracker.start();
    },
    stopHeadDirectionControl() {
      if (this.headTracker) {
        this.headTracker.stop();
      }

      this.headTracker = null;
    },
    handleHeadDirection(action) {
      if (this.data.status !== 'playing') {
        return false;
      }

      if (this.setAbsoluteDirection(action)) {
        this.setData({
          controlHint: `检测到头部${DIRECTION_TEXT[action]}，蛇转向${DIRECTION_TEXT[action]}。`
        });
        return true;
      }

      this.setData({
        controlHint: `检测到头部${DIRECTION_TEXT[action]}，当前方向不可直接转向。`
      });
      return false;
    },
    handleSlideEvent(event) {
      const slideEvent = Tools.getSlideEvent(event);
      const slide = slideEvent.slide;

      if (slide === 'forward') {
        Tools.preventDefault(event);
        this.turnLeft();
        this.setData({
          controlHint: '检测到前滑，蛇左转。'
        });
        return;
      }

      if (slide === 'backward') {
        Tools.preventDefault(event);
        this.turnRight();
        this.setData({
          controlHint: '检测到后滑，蛇右转。'
        });
      }
    },
    onKeyUp(event) {
      this.handleSlideEvent(event);
    }
  };
}
