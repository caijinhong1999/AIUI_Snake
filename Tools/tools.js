const IMU_DEFAULT_OPTIONS = {
  frequency: 60,
  resetDegrees: 2,
  minStableReadings: 1,
  debounceMs: 260,
  gyroNoiseFloor: 0.003,
  angleTriggerDegrees: {
    left: 2,
    right: 2,
    up: 2,
    down: 2
  },
  speedTriggerDegrees: {
    left: 2,
    right: 2,
    up: 2,
    down: 2
  },
  speedTriggerDegreesPerSecond: {
    left: 2,
    right: 2,
    up: 2,
    down: 2
  }
};

function getOptionValue(value, fallback) {
  return value === undefined || value === null ? fallback : value;
}

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

function mergeImuOptions(options) {
  const customOptions = options || {};

  return {
    frequency: getOptionValue(customOptions.frequency, IMU_DEFAULT_OPTIONS.frequency),
    resetDegrees: getOptionValue(customOptions.resetDegrees, IMU_DEFAULT_OPTIONS.resetDegrees),
    minStableReadings: getOptionValue(customOptions.minStableReadings, IMU_DEFAULT_OPTIONS.minStableReadings),
    debounceMs: getOptionValue(customOptions.debounceMs, IMU_DEFAULT_OPTIONS.debounceMs),
    gyroNoiseFloor: getOptionValue(customOptions.gyroNoiseFloor, IMU_DEFAULT_OPTIONS.gyroNoiseFloor),
    angleTriggerDegrees: {
      ...IMU_DEFAULT_OPTIONS.angleTriggerDegrees,
      ...(customOptions.angleTriggerDegrees || {})
    },
    speedTriggerDegrees: {
      ...IMU_DEFAULT_OPTIONS.speedTriggerDegrees,
      ...(customOptions.speedTriggerDegrees || {})
    },
    speedTriggerDegreesPerSecond: {
      ...IMU_DEFAULT_OPTIONS.speedTriggerDegreesPerSecond,
      ...(customOptions.speedTriggerDegreesPerSecond || {})
    },
    onActivate: customOptions.onActivate,
    onError: customOptions.onError,
    onReading: customOptions.onReading,
    onAction: customOptions.onAction,
    onReset: customOptions.onReset
  };
}

function isOnActionSide(action, axisDelta, options) {
  const horizontal = getHorizontalAxis(axisDelta);
  const vertical = axisDelta.x;
  const trigger = options.speedTriggerDegrees;

  if (action === 'left') {
    return horizontal >= trigger.left;
  }

  if (action === 'right') {
    return horizontal <= -trigger.right;
  }

  if (action === 'up') {
    return vertical >= trigger.up;
  }

  if (action === 'down') {
    return vertical <= -trigger.down;
  }

  return false;
}

function getPositionAction(axisDelta, options) {
  const horizontal = getHorizontalAxis(axisDelta);
  const vertical = axisDelta.x;
  const horizontalAction = horizontal >= 0 ? 'left' : 'right';
  const verticalAction = vertical >= 0 ? 'up' : 'down';
  const horizontalAbs = Math.abs(horizontal);
  const verticalAbs = Math.abs(vertical);
  const angleTrigger = options.angleTriggerDegrees;
  const horizontalReady = horizontalAbs >= angleTrigger[horizontalAction];
  const verticalReady = verticalAbs >= angleTrigger[verticalAction];

  if (!horizontalReady && !verticalReady) {
    return '';
  }

  if (horizontalReady && verticalReady) {
    const horizontalStrength = horizontalAbs / angleTrigger[horizontalAction];
    const verticalStrength = verticalAbs / angleTrigger[verticalAction];

    return horizontalStrength >= verticalStrength ? horizontalAction : verticalAction;
  }

  return horizontalReady ? horizontalAction : verticalAction;
}

function getFastestSpeedAction(axisSpeed, options) {
  const safeSpeed = axisSpeed || { x: 0, y: 0, z: 0 };
  const horizontalSpeed = getHorizontalSpeed(safeSpeed);
  const verticalSpeed = safeSpeed.x || 0;
  const horizontalAction = horizontalSpeed >= 0 ? 'left' : 'right';
  const verticalAction = verticalSpeed >= 0 ? 'up' : 'down';
  const horizontalAbs = Math.abs(horizontalSpeed);
  const verticalAbs = Math.abs(verticalSpeed);
  const speedTrigger = options.speedTriggerDegreesPerSecond;
  const horizontalReady = horizontalAbs >= speedTrigger[horizontalAction];
  const verticalReady = verticalAbs >= speedTrigger[verticalAction];

  if (!horizontalReady && !verticalReady) {
    return '';
  }

  if (horizontalReady && verticalReady) {
    const horizontalStrength = horizontalAbs / speedTrigger[horizontalAction];
    const verticalStrength = verticalAbs / speedTrigger[verticalAction];

    return horizontalStrength >= verticalStrength ? horizontalAction : verticalAction;
  }

  return horizontalReady ? horizontalAction : verticalAction;
}

function getHeadAction(axisDelta, axisSpeed, options) {
  const positionAction = getPositionAction(axisDelta, options);
  const speedAction = getFastestSpeedAction(axisSpeed, options);

  if (positionAction) {
    return positionAction;
  }

  return speedAction;
}

class Tools {
  static getKeyCode(event) {
    return event && (event.code || event.key || event.keyCode || event.detail && (event.detail.code || event.detail.key || event.detail.keyCode));
  }

  static preventDefault(event) {
    if (event && typeof event.preventDefault === 'function') {
      event.preventDefault();
    }
  }

  static normalizeSlideKey(code) {
    const slideMap = {
      ArrowDown: 'forward',
      Down: 'forward',
      40: 'forward',
      ArrowUp: 'backward',
      Up: 'backward',
      38: 'backward'
    };

    return slideMap[code] || '';
  }

  static getSlideEvent(event) {
    const code = Tools.getKeyCode(event);

    return {
      code,
      slide: Tools.normalizeSlideKey(code)
    };
  }

  static getHeadAction(axisDelta, axisSpeed, options) {
    return getHeadAction(axisDelta, axisSpeed, mergeImuOptions(options));
  }

  static createHeadDirectionTracker(options) {
    const trackerOptions = mergeImuOptions(options);

    return {
      sensor: null,
      gyroDelta: { x: 0, y: 0, z: 0 },
      gyroSpeed: { x: 0, y: 0, z: 0 },
      lastGyroTimestamp: null,
      pendingAction: '',
      pendingCount: 0,
      activeAction: '',
      lastTriggerAt: 0,
      start() {
        const GyroscopeConstructor = getGyroscopeConstructor();

        this.stop();
        this.reset();

        if (!GyroscopeConstructor) {
          if (typeof trackerOptions.onError === 'function') {
            trackerOptions.onError('当前环境不支持 Gyroscope');
          }
          return false;
        }

        try {
          this.sensor = new GyroscopeConstructor({ frequency: trackerOptions.frequency });
          this.sensor.addEventListener('activate', () => {
            if (typeof trackerOptions.onActivate === 'function') {
              trackerOptions.onActivate();
            }
          });
          this.sensor.addEventListener('reading', () => {
            this.handleReading();
          });
          this.sensor.addEventListener('error', (event) => {
            if (typeof trackerOptions.onError === 'function') {
              trackerOptions.onError(getReadableSensorError(event));
            }
          });
          this.sensor.start();
          return true;
        } catch (error) {
          if (typeof trackerOptions.onError === 'function') {
            trackerOptions.onError(error && error.message || 'Gyroscope 启动失败');
          }
          return false;
        }
      },
      stop() {
        if (this.sensor && typeof this.sensor.stop === 'function') {
          this.sensor.stop();
        }

        this.sensor = null;
      },
      reset() {
        this.gyroDelta = { x: 0, y: 0, z: 0 };
        this.gyroSpeed = { x: 0, y: 0, z: 0 };
        this.lastGyroTimestamp = null;
        this.pendingAction = '';
        this.pendingCount = 0;
        this.activeAction = '';
        this.lastTriggerAt = 0;

        if (typeof trackerOptions.onReset === 'function') {
          trackerOptions.onReset();
        }
      },
      triggerAction(action) {
        const now = Date.now();

        if (!action || this.activeAction === action || now - this.lastTriggerAt < trackerOptions.debounceMs) {
          return;
        }

        if (isOppositeSameAxisAction(this.activeAction, action) && !isOnActionSide(action, this.gyroDelta, trackerOptions)) {
          return;
        }

        let shouldConsumeAction = true;
        if (typeof trackerOptions.onAction === 'function') {
          const result = trackerOptions.onAction(action, {
            axisDelta: this.gyroDelta,
            axisSpeed: this.gyroSpeed
          });
          shouldConsumeAction = result !== false;
        }

        if (!shouldConsumeAction) {
          return;
        }

        this.activeAction = action;
        this.lastTriggerAt = now;
      },
      handleAxisDelta() {
        const horizontal = getHorizontalAxis(this.gyroDelta);
        const nextAction = getHeadAction(this.gyroDelta, this.gyroSpeed, trackerOptions);

        if (Math.abs(this.gyroDelta.x) < trackerOptions.resetDegrees && Math.abs(horizontal) < trackerOptions.resetDegrees) {
          this.activeAction = '';
          this.pendingAction = '';
          this.pendingCount = 0;

          if (typeof trackerOptions.onReading === 'function') {
            trackerOptions.onReading({
              axisDelta: this.gyroDelta,
              axisSpeed: this.gyroSpeed,
              action: '',
              isCentered: true
            });
          }
          return;
        }

        if (nextAction) {
          if (this.pendingAction === nextAction) {
            this.pendingCount += 1;
          } else {
            this.pendingAction = nextAction;
            this.pendingCount = 1;
          }

          if (this.pendingCount >= trackerOptions.minStableReadings) {
            this.triggerAction(nextAction);
          }
        }

        if (typeof trackerOptions.onReading === 'function') {
          trackerOptions.onReading({
            axisDelta: this.gyroDelta,
            axisSpeed: this.gyroSpeed,
            action: nextAction,
            isCentered: false
          });
        }
      },
      handleReading() {
        const sensor = this.sensor;

        if (!sensor) {
          return;
        }

        const timestamp = sensor.timestamp || Date.now();

        if (this.lastGyroTimestamp === null) {
          this.lastGyroTimestamp = timestamp;

          if (typeof trackerOptions.onReading === 'function') {
            trackerOptions.onReading({
              axisDelta: this.gyroDelta,
              axisSpeed: this.gyroSpeed,
              action: '',
              isInitialized: true,
              isCentered: true
            });
          }
          return;
        }

        let dt = timestamp - this.lastGyroTimestamp;

        if (dt > 1) {
          dt = dt / 1000;
        }

        dt = Math.max(0, Math.min(dt, 0.08));
        this.lastGyroTimestamp = timestamp;

        const x = Math.abs(sensor.x || 0) < trackerOptions.gyroNoiseFloor ? 0 : sensor.x || 0;
        const y = Math.abs(sensor.y || 0) < trackerOptions.gyroNoiseFloor ? 0 : sensor.y || 0;
        const z = Math.abs(sensor.z || 0) < trackerOptions.gyroNoiseFloor ? 0 : sensor.z || 0;

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

        this.handleAxisDelta();
      }
    };
  }
}

export default Tools;
