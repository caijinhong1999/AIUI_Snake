<script def>
{
  "navigationBarTitleText": "AIUI Snake"
}
</script>

<script setup>
import wx from 'wx';
import Tools from '../../Tools/tools.js';

const MODES = ['classic', 'infinite', 'testIMU'];

export default {
  data: {
    selectedMode: 'infinite',
    classicModeClass: '',
    infiniteModeClass: 'selected',
    testArrowModeClass: '',
    testIMUModeClass: '',
    homeHint: '再次点击或按确认键进入无限流模式'
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
  selectTestArrowMode() {
    this.setData({
      homeHint: '滑动测试已禁用，请选择传统模式'
    });
  },
  selectTestIMUMode() {
    if (this.data.selectedMode === 'testIMU') {
      this.openSelectedMode();
      return;
    }

    this.setSelectedMode('testIMU');
  },
  setSelectedMode(mode) {
    const hintMap = {
      classic: '再次点击或按确认键进入传统模式',
      infinite: '再次点击或按确认键进入无限流模式',
      testArrow: '滑动测试已禁用',
      testIMU: '再次点击或按确认键进入 IMU 测试'
    };

    this.setData({
      selectedMode: mode,
      classicModeClass: mode === 'classic' ? 'selected' : '',
      infiniteModeClass: mode === 'infinite' ? 'selected' : '',
      testArrowModeClass: mode === 'testArrow' ? 'selected' : '',
      testIMUModeClass: mode === 'testIMU' ? 'selected' : '',
      homeHint: hintMap[mode] || ''
    });
  },
  changeSelection(step) {
    const currentIndex = MODES.indexOf(this.data.selectedMode);
    const nextIndex = (currentIndex + step + MODES.length) % MODES.length;

    this.setSelectedMode(MODES[nextIndex]);
  },
  openSelectedMode() {
    if (this.data.selectedMode === 'testIMU') {
      if (wx && typeof wx.navigateTo === 'function') {
        wx.navigateTo({
          url: '/pages/test/testIMU'
        });
        return;
      }

      this.setData({
        homeHint: '当前环境不支持页面跳转'
      });
      return;
    }

    if (this.data.selectedMode === 'testArrow') {
      this.setData({
        homeHint: '滑动测试已禁用，请选择传统模式'
      });
      return;
    }

    if (wx && typeof wx.navigateTo === 'function') {
      if (this.data.selectedMode === 'infinite') {
        wx.navigateTo({
          url: '/pages/game/infinite?mode=infinite'
        });
        return;
      }

      wx.navigateTo({
        url: '/pages/game/traditional?mode=classic'
      });
      return;
    }

    this.setData({
      homeHint: '当前环境不支持页面跳转'
    });
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
    const slideEvent = Tools.getSlideEvent(event);
    const code = slideEvent.code;
    const slide = slideEvent.slide;

    if (this.shouldSkipDuplicateKey(code)) {
      return;
    }

    if (slide === 'backward') {
      Tools.preventDefault(event);
      this.changeSelection(-1);
      return;
    }

    if (slide === 'forward') {
      Tools.preventDefault(event);
      this.changeSelection(1);
      return;
    }

    if (this.isConfirmKey(code)) {
      Tools.preventDefault(event);
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

      <view class="mode-button {{ infiniteModeClass }}" bindtap="selectInfiniteMode">
        <text class="mode-title">无限流模式</text>
        <text class="mode-copy">穿墙循环，只会撞到自己</text>
      </view>

      <view class="mode-button {{ testArrowModeClass }} disabled" bindtap="selectTestArrowMode">
        <text class="mode-title">滑动测试</text>
        <text class="mode-copy">测试前滑和后滑触发</text>
      </view>

      <view class="mode-button {{ testIMUModeClass }}" bindtap="selectTestIMUMode">
        <text class="mode-title">IMU 测试</text>
        <text class="mode-copy">识别头部左转右转和上下移动</text>
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
  margin-bottom: 18px;
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
  gap: 8px;
  width: 300px;
}

.mode-button {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  width: 100%;
  min-height: 58px;
  padding: 8px 14px;
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
  font-size: 18px;
  line-height: 22px;
  font-weight: 700;
}

.mode-copy {
  font-size: 11px;
  line-height: 15px;
  color: #9be46c;
  margin-top: 2px;
}
</style>
