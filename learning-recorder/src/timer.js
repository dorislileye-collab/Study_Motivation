/**
 * 计时页模块 - 任务选择 + 双模式计时 + 完成流程
 */
import { store } from './store.js';
import { playRewardSound, playCoinSound, playTimerEndSound, playClickSound } from './sound.js';
import { showCelebration } from './celebration.js';
import { getTimerCelebrationImage } from './decoration-manager.js';
import { renderWhiteNoisePanel, bindWhiteNoiseEvents, stopWhiteNoise } from './white-noise.js';

// 计时状态
let timerState = null;
let timerInterval = null;

/** 初始化计时页 */
export function initTimer() {
  renderTimerPage();
}

/** 渲染计时页（初始状态：任务选择） */
export function renderTimerPage() {
  const page = document.getElementById('page-timer');
  const today = store.getToday();
  const tasks = store.getTasksByDate(today);
  const uncompleted = tasks.filter(t => !t.completed);

  if (timerState) {
    // 正在计时中，显示计时界面
    renderTimerInterface(page);
    return;
  }

  page.innerHTML = `
    <h2>⏱ 计时学习</h2>

    ${uncompleted.length === 0
      ? '<div class="card"><div class="empty-hint">🎉 今日任务已全部完成！</div></div>'
      : `
    <div class="card">
      <h3>选择任务</h3>
      <div class="task-select-list">
        ${uncompleted.map(t => `
          <div class="task-select-item" data-id="${t.id}">
            <span class="task-select-title">${escapeHtml(t.title)}</span>
            <span class="task-select-mode">${getModeLabel(t)}</span>
          </div>
        `).join('')}
      </div>
    </div>
    `}

    <div class="timer-mode-switch">
      <h3>计时模式</h3>
      <div class="mode-cards">
        <div class="mode-card mode-card-static">
          <div class="mode-icon">⏱</div>
          <div class="mode-name">时间模式</div>
          <div class="mode-desc">设定目标时长<br>正计时到达后自动停止</div>
        </div>
        <div class="mode-card mode-card-static">
          <div class="mode-icon">🔢</div>
          <div class="mode-name">次数模式</div>
          <div class="mode-desc">设定目标次数<br>同时计时，达成后停止</div>
        </div>
        <div class="mode-card mode-card-static">
          <div class="mode-icon">🆓</div>
          <div class="mode-name">自由模式</div>
          <div class="mode-desc">不设目标随意计时<br>随时开始随时结束</div>
        </div>
      </div>
      <div class="mode-hint">💡 点击上方任务即可开始，模式由任务设定</div>
    </div>
  `;

  // 绑定任务选择
  document.querySelectorAll('.task-select-item').forEach(item => {
    item.addEventListener('click', () => {
      playClickSound();
      const id = item.dataset.id;
      const task = store.getTasksByDate(today).find(t => t.id === id);
      if (task) {
        startTimer(task);
      }
    });
  });
}

/** 开始计时（模式由任务自身决定：有duration为时间模式，有count为次数模式，都没有为自由模式） */
function startTimer(task) {
  const mode = task.duration ? 'time' : task.count ? 'count' : 'free';

  timerState = {
    taskId: task.id,
    taskTitle: task.title,
    mode,
    elapsed: 0,          // 已用秒数
    targetTime: task.duration || null,  // 目标秒数（自由模式无目标）
    targetCount: task.count || null,    // 目标次数（自由模式无目标）
    currentCount: task.currentCount || 0,  // 已完成次数
    isRunning: false,
  };

  renderTimerInterface(document.getElementById('page-timer'));
}

/** 渲染计时界面 */
function renderTimerInterface(page) {
  if (!timerState) return;

  const { mode, elapsed, targetTime, targetCount, currentCount, isRunning } = timerState;
  const mins = Math.floor(elapsed / 60);
  const secs = elapsed % 60;
  const timeStr = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

  const targetMins = Math.floor(targetTime / 60);
  const progress = mode === 'time' && targetTime
    ? Math.min(100, (elapsed / targetTime) * 100)
    : mode === 'count' && targetCount
    ? Math.min(100, (currentCount / targetCount) * 100)
    : 0;

  // 模式标签
  const modeBadge = mode === 'time' ? '\u23F1 时间模式' : mode === 'count' ? '\uD83D\uDD22 次数模式' : '\uD83C\uDD93 自由模式';
  const timerLabel = mode === 'time' ? '已用时' : mode === 'count' ? '计时中' : '自由计时';

  page.innerHTML = `
    <div class="timer-active-page">
      <!-- 任务信息 -->
      <div class="timer-task-info">
        <span class="timer-task-name">${escapeHtml(timerState.taskTitle)}</span>
        <span class="timer-mode-badge">${modeBadge}</span>
      </div>

      <!-- 大计时器 -->
      <div class="timer-display">
        <div class="timer-circle" style="--progress: ${progress}">
          <div class="timer-time">${timeStr}</div>
          <div class="timer-label">${timerLabel}</div>
        </div>
      </div>

      <!-- 目标进度（自由模式不显示进度条） -->
      ${mode === 'time' && targetTime ? `
        <div class="timer-target-info">
          目标 ${Math.floor(targetTime / 60)} 分钟
          <div class="timer-progress-bar">
            <div class="timer-progress-fill" style="width: ${progress}%"></div>
          </div>
        </div>
      ` : mode === 'count' && targetCount ? `
        <div class="timer-target-info">
          进度 ${currentCount} / ${targetCount} 次 · 已用时 ${timeStr}
          <div class="timer-progress-bar">
            <div class="timer-progress-fill" style="width: ${progress}%"></div>
          </div>
        </div>
      ` : `
        <div class="timer-target-info timer-free-info">
          自由计时 · 已用时 ${timeStr}
        </div>
      `}

      <!-- 控制按钮 -->
      <div class="timer-controls">
        ${mode === 'count' ? `
          <button class="btn-timer-control ${isRunning ? 'btn-pause' : 'btn-start'}" id="btn-timer-toggle">
            ${isRunning ? '⏸ 暂停' : '▶ 开始计时'}
          </button>
          <button class="btn-timer-control btn-count" id="btn-timer-count" ${!isRunning ? 'disabled' : ''}>
            ${currentCount >= targetCount ? `🎉 目标达成！(${currentCount}/${targetCount})` : `✅ 完成一次 (${currentCount}/${targetCount})`}
          </button>
          <button class="btn-timer-control btn-end" id="btn-timer-end"> 结束</button>
        ` : `
          <button class="btn-timer-control ${isRunning ? 'btn-pause' : 'btn-start'}" id="btn-timer-toggle">
            ${isRunning ? '⏸ 暂停' : '▶ 开始'}
          </button>
          <button class="btn-timer-control btn-reset" id="btn-timer-reset"> 重置</button>
          <button class="btn-timer-control btn-end" id="btn-timer-end">⏹ 结束</button>
        `}
      </div>

      <!-- 白噪音面板 -->
      ${renderWhiteNoisePanel()}
    </div>
  `;

  // 绑定控制事件
  const btnToggle = document.getElementById('btn-timer-toggle');
  const btnReset = document.getElementById('btn-timer-reset');
  const btnEnd = document.getElementById('btn-timer-end');
  const btnCount = document.getElementById('btn-timer-count');

  if (btnToggle) {
    btnToggle.addEventListener('click', () => toggleTimer());
  }
  if (btnReset) {
    btnReset.addEventListener('click', () => resetTimer());
  }
  if (btnEnd) {
    btnEnd.addEventListener('click', () => endTimer());
  }
  if (btnCount) {
    btnCount.addEventListener('click', () => {
      if (!timerState.isRunning) return;
      playClickSound();
      timerState.currentCount++;
      if (timerState.currentCount >= timerState.targetCount) {
        // 次数达成：停止计时，走与时间模式一致的完成流程
        clearInterval(timerInterval);
        timerInterval = null;
        timerState.isRunning = false;
        playTimerEndSound();
        showTimerComplete();
      } else {
        renderTimerInterface(page);
      }
    });
  }

  // 绑定白噪音事件
  bindWhiteNoiseEvents();
}

/** 开始/暂停计时 */
function toggleTimer() {
  if (timerState.isRunning) {
    // 暂停
    clearInterval(timerInterval);
    timerInterval = null;
    timerState.isRunning = false;
  } else {
    // 开始
    timerState.isRunning = true;
    timerInterval = setInterval(() => {
      timerState.elapsed++;
      store.addStudyTime(1);

      // 检查是否到达目标时间
      if (timerState.mode === 'time' && timerState.elapsed >= timerState.targetTime) {
        clearInterval(timerInterval);
        timerInterval = null;
        timerState.isRunning = false;
        playTimerEndSound();
        showTimerComplete();
        return;
      }

      // 刷新显示
      const page = document.getElementById('page-timer');
      if (page) {
        if (timerState.mode === 'count') {
          // 次数模式每10秒刷新一次
          if (timerState.elapsed % 10 === 0) renderTimerInterface(page);
        } else {
          // 时间模式和自由模式每秒刷新
          renderTimerInterface(page);
        }
      }
    }, 1000);
  }

  const page = document.getElementById('page-timer');
  if (page) renderTimerInterface(page);
}

/** 重置计时 */
function resetTimer() {
  clearInterval(timerInterval);
  timerInterval = null;
  timerState.elapsed = 0;
  timerState.currentCount = 0;
  timerState.isRunning = false;
  stopWhiteNoise();
  const page = document.getElementById('page-timer');
  if (page) renderTimerInterface(page);
}

/** 结束计时 */
function endTimer() {
  clearInterval(timerInterval);
  timerInterval = null;
  timerState.isRunning = false;

  // 如果用时太短（少于10秒），直接返回
  if (timerState.elapsed < 10 && timerState.currentCount === 0) {
    if (confirm('计时时间太短，确定要结束吗？')) {
      timerState = null;
      renderTimerPage();
    } else {
      // 重新开始
      timerState.isRunning = false;
      const page = document.getElementById('page-timer');
      if (page) renderTimerInterface(page);
    }
    return;
  }

  showTimerComplete();
}

/** 显示计时完成 + 填写心得 */
function showTimerComplete() {
  const page = document.getElementById('page-timer');
  const { elapsed, currentCount, targetCount, taskTitle } = timerState;
  const mins = Math.floor(elapsed / 60);
  const secs = elapsed % 60;
  const timeStr = `${mins}分${secs}秒`;

  // 播放奖励音效
  playRewardSound();

  // 显示祝贺特效
  showCelebration(3000);

  // 获取庆祝装饰图片
  const celebImg = getTimerCelebrationImage();

  page.innerHTML = `
    <div class="timer-complete-page">
      ${celebImg ? `<img class="timer-celebration-img" src="${celebImg}" alt="">` : '<div class="complete-icon">🎉</div>'}
      <h2>太棒了！</h2>
      <div class="complete-stats">
        <div class="stat-item">
          <span class="stat-label">任务</span>
          <span class="stat-value">${escapeHtml(taskTitle)}</span>
        </div>
        <div class="stat-item">
          <span class="stat-label">用时</span>
          <span class="stat-value">${timeStr}</span>
        </div>
        ${timerState.mode === 'count' ? `
        <div class="stat-item">
          <span class="stat-label">完成次数</span>
          <span class="stat-value">${currentCount}/${targetCount}</span>
        </div>
        ` : ''}
      </div>

      <div class="card">
        <h3>📝 写下学习心得</h3>
        <textarea id="input-notes" placeholder="今天学到了什么？有什么收获？" rows="3" maxlength="200"></textarea>
      </div>

      <button class="btn-primary" id="btn-save-complete">💾 保存并领取奖励</button>
    </div>
  `;

  document.getElementById('btn-save-complete').addEventListener('click', () => {
    const notes = document.getElementById('input-notes').value.trim();
    completeTimer(notes);
  });
}

/** 完成计时 - 发放奖励 */
function completeTimer(notes) {
  const { taskId, elapsed } = timerState;
  const today = store.getToday();

  // 保存学习心得
  if (notes) {
    store.addNote(today, notes);
  }

  // 更新任务为已完成
  store.updateTask(taskId, {
    completed: true,
    elapsed: elapsed,
    notes: notes || '',
  });

  // 记录打卡
  store.recordActive();

  // 计算金币奖励（新规则：每30分钟=30金币，1分钟=1金币）
  const mins = Math.floor(elapsed / 60);
  const coinFromTime = mins; // 1分钟=1金币，30分钟=30金币
  const earnedTime = store.addCoins(coinFromTime, `计时${mins}分钟`);

  // 每日首次计时完成奖励50金币（一天一次）
  const bufferResult = store.claimDailyBuffer();
  let earnedBuffer = 0;
  if (bufferResult.claimed) {
    earnedBuffer = bufferResult.coins;
  }

  // 检查是否全部完成
  const allTasks = store.getTasksByDate(today);
  const allCompleted = allTasks.length > 0 && allTasks.every(t => t.completed);
  let earnedBonus = 0;
  if (allCompleted) {
    earnedBonus = store.addCoins(50, '完成每日全部任务');
  }

  // 检查连续打卡奖励
  const streak = store.getStreakDays();
  let earnedStreak = 0;
  if (streak >= 7 && streak % 7 === 0) {
    earnedStreak = store.addCoins(100, `连续打卡${streak}天`);
  }

  // 播放金币音效
  if (earnedTime + earnedBuffer + earnedBonus + earnedStreak > 0) {
    setTimeout(() => playCoinSound(), 500);
  }

  // 清除计时状态
  timerState = null;
  clearInterval(timerInterval);
  timerInterval = null;
  stopWhiteNoise();

  // 显示奖励结果
  const page = document.getElementById('page-timer');
  const totalEarned = earnedTime + earnedBuffer + earnedBonus + earnedStreak;
  page.innerHTML = `
    <div class="reward-result-page">
      <div class="complete-icon"></div>
      <h2>奖励已领取！</h2>
      ${totalEarned > 0 ? `
      <div class="coin-fly-animation" id="coin-fly">+${totalEarned}</div>
      ` : ''}
      <div class="reward-details">
        ${earnedBuffer > 0 ? `<div class="reward-item">🎁 每日首次计时 +${earnedBuffer} 金币</div>` : ''}
        ${earnedTime > 0 ? `<div class="reward-item">⏱ 计时${mins}分钟 +${earnedTime} 金币</div>` : ''}
        ${earnedBonus > 0 ? `<div class="reward-item">🏆 全部完成 +${earnedBonus} 金币</div>` : ''}
        ${earnedStreak > 0 ? `<div class="reward-item">🔥 连续打卡${streak}天 +${earnedStreak} 金币</div>` : ''}
        ${totalEarned === 0 ? '<div class="reward-item">💡 计时即可获得金币奖励（1分钟=1金币）</div>' : ''}
      </div>
      <div class="coin-balance">💰 当前余额：${store.getCoins()} 金币</div>
      <button class="btn-primary" id="btn-back-home"> 返回首页</button>
    </div>
  `;

  document.getElementById('btn-back-home').addEventListener('click', () => {
    // 切换到首页Tab
    document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
    document.querySelector('[data-page="page-home"]').classList.add('active');
    document.getElementById('page-home').classList.add('active');
    // 动态导入并渲染首页
    import('./home.js').then(m => m.renderHome());
  });
}

/** 获取模式标签 */
function getModeLabel(task) {
  if (task.duration) return `⏱ ${Math.floor(task.duration / 60)}分钟`;
  if (task.count) return `🔢 ${task.count}次`;
  return '自由计时';
}

/** HTML转义 */
function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}
