<script def>
{
  "navigationBarTitleText": "AIUI Snake"
}
</script>

<script setup>
import wx from 'wx';

const MODES = ['classic', 'infinite'];

export default {
  data: {
    selectedMode: 'classic',
    classicModeClass: 'selected',
    infiniteModeClass: '',
    homeHint: '按上下键选择，确认键进入'
  },
  selectClassicMode() {
    if (this.data.selectedMode === 'classic') {
      this.openSelectedMode();
      return;
    }

    this.setSelectedMode('classic');
  },
  selectInfiniteMode() {
    if (this.data.selectedMode === 'infinite') {
      this.openSelectedMode();
      return;
    }

    this.setSelectedMode('infinite');
  },
  setSelectedMode(mode) {
    this.setData({
      selectedMode: mode,
      classicModeClass: mode === 'classic' ? 'selected' : '',
      infiniteModeClass: mode === 'infinite' ? 'selected' : '',
      homeHint: mode === 'classic' ? '再次点击或按确认键进入传统模式' : '无限流模式尚未实现'
    });
  },
  changeSelection(step) {
    const currentIndex = MODES.indexOf(this.data.selectedMode);
    const nextIndex = (currentIndex + step + MODES.length) % MODES.length;

    this.setSelectedMode(MODES[nextIndex]);
  },
  openSelectedMode() {
    if (this.data.selectedMode !== 'classic') {
      this.setData({
        homeHint: '无限流模式尚未实现，请选择传统模式'
      });
      return;
    }

    if (wx && typeof wx.navigateTo === 'function') {
      wx.navigateTo({
        url: '/pages/game/game?mode=classic'
      });
      return;
    }

    this.setData({
      homeHint: '当前环境不支持页面跳转'
    });
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
      40: 'down'
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

    if (direction === 'up') {
      this.preventDefault(event);
      this.changeSelection(-1);
      return;
    }

    if (direction === 'down') {
      this.preventDefault(event);
      this.changeSelection(1);
      return;
    }

    if (this.isConfirmKey(code)) {
      this.preventDefault(event);
      this.openSelectedMode();
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
  <view class="home">
    <view class="brand">
      <text class="kicker">AIUI Snake</text>
      <text class="title">贪吃蛇</text>
      <text class="subtitle">选择关卡模式</text>
      <text class="hint">{{ homeHint }}</text>
    </view>

    <view class="mode-list">
      <view class="mode-button {{ classicModeClass }}" bindtap="selectClassicMode">
        <text class="mode-title">传统模式</text>
        <text class="mode-copy">撞墙或撞到自己即结束</text>
      </view>

      <view class="mode-button {{ infiniteModeClass }} disabled" bindtap="selectInfiniteMode">
        <text class="mode-title">无限流模式</text>
        <text class="mode-copy">穿墙循环，后续接入</text>
      </view>
    </view>
  </view>
</page>

<style>
.home {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  box-sizing: border-box;
  width: 100%;
  height: 100vh;
  padding: 28px;
  background: #062414;
  color: #caff8d;
}

.brand {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 28px;
}

.kicker {
  color: #72ff62;
  font-size: 14px;
  line-height: 18px;
  margin-bottom: 8px;
}

.title {
  color: #d8ff8a;
  font-size: 42px;
  line-height: 48px;
  font-weight: 700;
}

.subtitle {
  color: #7fd96a;
  font-size: 18px;
  line-height: 24px;
  margin-top: 8px;
}

.hint {
  color: #9be46c;
  font-size: 13px;
  line-height: 18px;
  margin-top: 10px;
}

.mode-list {
  display: flex;
  flex-direction: column;
  gap: 14px;
  width: 300px;
}

.mode-button {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  width: 100%;
  min-height: 78px;
  padding: 12px 16px;
  border: 2px solid #297c3a;
  border-radius: 8px;
  background: #0d351e;
  color: #caff8d;
  box-sizing: border-box;
}

.mode-button.selected {
  border-color: #72ff62;
  background: #123f22;
}

.mode-button.disabled {
  opacity: 0.45;
}

.mode-title {
  font-size: 22px;
  line-height: 28px;
  font-weight: 700;
}

.mode-copy {
  font-size: 13px;
  line-height: 18px;
  color: #9be46c;
  margin-top: 4px;
}
</style>
