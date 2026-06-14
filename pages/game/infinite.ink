<script def>
{
  "navigationBarTitleText": "无限流模式"
}
</script>

<script setup>
import { createSnakeGamePage } from '../../public/public.js';

export default createSnakeGamePage({
  statusText: '无限流模式',
  wrapWalls: true
});
</script>

<page>
  <view class="game">
    <view class="hud">
      <view class="hud-main">
        <text class="control-hint">{{ controlHint }}</text>
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
.control-hint {
  color: #8ee05f;
  font-size: 12px;
  line-height: 14px;
}

.control-hint {
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
