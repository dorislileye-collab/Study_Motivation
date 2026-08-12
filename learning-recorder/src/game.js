/**
 * 游戏页模块 - 解锁逻辑 + 20分钟限制 + 冻结机制
 */
import { store } from './store.js';
import { refreshDecorations } from './decoration-manager.js';

let gameTimerInterval = null;
let isFrozen = false;
let sandCleanup = null;
let bubbleCleanup = null;
let crushCleanup = null;

function cleanupActiveMiniGames() {
  if (sandCleanup) {
    sandCleanup();
    sandCleanup = null;
  }
  if (bubbleCleanup) {
    bubbleCleanup();
    bubbleCleanup = null;
  }
  if (crushCleanup) {
    crushCleanup();
    crushCleanup = null;
  }
}

/** 初始化游戏页 */
export function initGame() {
  renderGamePage();
}

/** 渲染游戏页 */
export function renderGamePage() {
  const page = document.getElementById('page-game');
  const today = store.getToday();
  const tasks = store.getTasksByDate(today);
  const completedCount = tasks.filter(t => t.completed).length;
  const hasCompletedTask = completedCount > 0;
  const gameTimeUsed = store.getGameTimeToday();
  const maxGameTime = 20 * 60; // 20分钟 = 1200秒
  const remainingSec = Math.max(0, maxGameTime - gameTimeUsed);
  const remainingMin = Math.floor(remainingSec / 60);
  const remainingSecLeft = remainingSec % 60;

  // 每次渲染都重算冻结状态，避免跨天后仍保持冻结
  isFrozen = gameTimeUsed >= maxGameTime;

  page.innerHTML = `
    <h2>🎮 解压游戏</h2>

    <!-- 时间状态栏 -->
    <div class="game-status-bar">
      ${hasCompletedTask
        ? `<span class="game-status-text">今日剩余：${remainingMin}:${String(remainingSecLeft).padStart(2, '0')}</span>`
        : '<span class="game-status-text locked">🔒 完成1个任务后解锁</span>'
      }
    </div>

    <!-- 游戏列表 -->
    <div class="game-list">
      <div class="game-card ${!hasCompletedTask ? 'locked' : ''}" data-game="sand">
        <div class="game-card-icon">️</div>
        <div class="game-card-info">
          <h3>沙画禅境</h3>
          <p>手指拖动画画，沙子随手指流动散开</p>
          <span class="game-tag">4种材质 · 无目标压力</span>
        </div>
      </div>

      <div class="game-card ${!hasCompletedTask ? 'locked' : ''}" data-game="bubble">
        <div class="game-card-icon"></div>
        <div class="game-card-info">
          <h3>泡泡星球</h3>
          <p>点击产生彩色泡泡，物理碰撞弹跳</p>
          <span class="game-tag">物理碰撞 · 戳破爽感</span>
        </div>
      </div>

      <div class="game-card ${!hasCompletedTask ? 'locked' : ''}" data-game="destroy">
        <div class="game-card-icon">💥</div>
        <div class="game-card-info">
          <h3>情绪粉碎机</h3>
          <p>写下烦恼，选择方式销毁它</p>
          <span class="game-tag">4种销毁方式 · 情绪宣泄</span>
        </div>
      </div>
    </div>

    ${!hasCompletedTask ? `
    <div class="game-lock-hint">
      <p>💡 完成今日任意1个任务后即可解锁游戏</p>
    </div>
    ` : ''}

    <!-- 冻结遮罩 -->
    ${isFrozen ? `
    <div class="game-freeze-overlay" id="game-freeze-overlay">
      <div class="freeze-content">
        <div class="freeze-icon">⏰</div>
        <h3>今日游戏时间已用完</h3>
        <p>明天再来玩吧！</p>
        <button class="btn-primary" id="btn-exit-frozen">退出</button>
      </div>
    </div>
    ` : ''}
  `;

  // 绑定游戏卡片点击
  if (hasCompletedTask && !isFrozen) {
    document.querySelectorAll('.game-card:not(.locked)').forEach(card => {
      card.addEventListener('click', () => {
        const gameType = card.dataset.game;
        enterGame(gameType);
      });
    });
  }

  // 冻结退出按钮
  const btnExit = document.getElementById('btn-exit-frozen');
  if (btnExit) {
    btnExit.addEventListener('click', () => {
      // 切换到首页
      document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
      document.querySelector('[data-page="page-home"]').classList.add('active');
      document.getElementById('page-home').classList.add('active');
      import('./home.js').then(m => m.renderHome());
    });
  }

  // 启动游戏时间倒计时
  if (hasCompletedTask && !isFrozen) {
    startGameTimer();
  }

  // 重渲染后重新注入游戏页装饰图片
  refreshDecorations();
}

/** 进入游戏 */
async function enterGame(gameType) {
  const page = document.getElementById('page-game');
  const gameNames = {
    sand: '沙画禅境',
    bubble: '泡泡星球',
    destroy: '情绪粉碎机',
  };

  // 沙画游戏特殊处理
  if (gameType === 'sand') {
    page.innerHTML = `
      <div class="game-playing-page">
        <div class="game-playing-header">
          <button class="btn-icon" id="btn-back-game-list"> 返回</button>
          <h3>️ 沙画禅境</h3>
          <span class="game-time-display" id="game-time-display">20:00</span>
        </div>
        <div class="sand-material-bar">
          <button class="material-btn active" data-material="sand">️ 细沙</button>
          <button class="material-btn" data-material="powder">🎨 彩色粉末</button>
          <button class="material-btn" data-material="star">✨ 星空粒子</button>
          <button class="material-btn" data-material="water">💧 水滴</button>
          <button class="material-btn reset-btn" id="btn-sand-reset">🔄 重置</button>
        </div>
        <div class="game-canvas-area" id="game-canvas-area"></div>
      </div>
    `;

    // 返回按钮
    document.getElementById('btn-back-game-list').addEventListener('click', () => {
      cleanupActiveMiniGames();
      renderGamePage();
    });

    // 材质切换
    document.querySelectorAll('.material-btn:not(.reset-btn)').forEach(btn => {
      btn.addEventListener('click', async () => {
        document.querySelectorAll('.material-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        const { setMaterial } = await import('./games/sand.js');
        setMaterial(btn.dataset.material);
      });
    });

    // 重置按钮
    document.getElementById('btn-sand-reset').addEventListener('click', async () => {
      const { resetCanvas } = await import('./games/sand.js');
      resetCanvas();
    });

    // 更新时间显示
    updateGameTimeDisplay();

    // 初始化沙画游戏
    const canvasArea = document.getElementById('game-canvas-area');
    const { initSandGame, setTimeDisplay } = await import('./games/sand.js');
    setTimeDisplay(document.getElementById('game-time-display'));
    sandCleanup = initSandGame(canvasArea);
    startGameTimer();
    refreshDecorations();

    return;
  }

  // 泡泡星球游戏
  if (gameType === 'bubble') {
    page.innerHTML = `
      <div class="game-playing-page">
        <div class="game-playing-header">
          <button class="btn-icon" id="btn-back-game-list"> 返回</button>
          <h3>🫧 泡泡星球</h3>
          <span class="game-time-display" id="game-time-display">20:00</span>
        </div>
        <div class="bubble-tips">点击产生泡泡 · 双击戳破</div>
        <div class="game-canvas-area" id="game-canvas-area"></div>
      </div>
    `;

    // 返回按钮
    document.getElementById('btn-back-game-list').addEventListener('click', () => {
      cleanupActiveMiniGames();
      renderGamePage();
    });

    // 更新时间显示
    updateGameTimeDisplay();

    // 初始化泡泡游戏
    const canvasArea = document.getElementById('game-canvas-area');
    const { initBubbleGame, setTimeDisplay } = await import('./games/bubble.js');
    setTimeDisplay(document.getElementById('game-time-display'));
    bubbleCleanup = initBubbleGame(canvasArea);
    startGameTimer();
    refreshDecorations();

    return;
  }

  // 情绪粉碎机游戏
  if (gameType === 'destroy') {
    page.innerHTML = `
      <div class="game-playing-page">
        <div class="game-playing-header">
          <button class="btn-icon" id="btn-back-game-list"> 返回</button>
          <h3>💥 情绪粉碎机</h3>
          <span class="game-time-display" id="game-time-display">20:00</span>
        </div>
        <div class="game-canvas-area" id="game-canvas-area"></div>
      </div>
    `;

    // 返回按钮
    document.getElementById('btn-back-game-list').addEventListener('click', () => {
      cleanupActiveMiniGames();
      renderGamePage();
    });

    // 更新时间显示
    updateGameTimeDisplay();

    // 初始化情绪粉碎机游戏
    const canvasArea = document.getElementById('game-canvas-area');
    const { initCrushGame, setTimeDisplay } = await import('./games/crush.js');
    setTimeDisplay(document.getElementById('game-time-display'));
    crushCleanup = initCrushGame(canvasArea);
    startGameTimer();
    refreshDecorations();

    return;
  }

  // 其他游戏占位
  page.innerHTML = `
    <div class="game-playing-page">
      <div class="game-playing-header">
        <button class="btn-icon" id="btn-back-game-list"> 返回</button>
        <h3>${gameNames[gameType]}</h3>
        <span class="game-time-display" id="game-time-display">20:00</span>
      </div>
      <div class="game-canvas-area" id="game-canvas-area">
        <div class="game-placeholder">
          <div class="game-placeholder-icon"></div>
          <p>${gameNames[gameType]}</p>
          <p class="game-placeholder-hint">游戏开发中...</p>
        </div>
      </div>
    </div>
  `;

  // 返回按钮
  document.getElementById('btn-back-game-list').addEventListener('click', () => {
    renderGamePage();
  });

  // 更新剩余时间显示
  updateGameTimeDisplay();
  refreshDecorations();
}

/** 启动游戏时间计时器 */
function startGameTimer() {
  // 清除旧的计时器
  if (gameTimerInterval) {
    clearInterval(gameTimerInterval);
  }

  gameTimerInterval = setInterval(() => {
    const gameTimeUsed = store.getGameTimeToday();
    const maxGameTime = 20 * 60;

    if (gameTimeUsed >= maxGameTime) {
      clearInterval(gameTimerInterval);
      gameTimerInterval = null;
      isFrozen = true;
      cleanupActiveMiniGames();
      renderGamePage(); // 重新渲染，显示冻结状态
      return;
    }

    // 每秒增加游戏时间
    store.addGameTime(1);
    updateGameTimeDisplay();
  }, 1000);
}

/** 更新游戏时间显示 */
function updateGameTimeDisplay() {
  const display = document.getElementById('game-time-display');
  if (!display) return;

  const remainingSec = Math.max(0, 20 * 60 - store.getGameTimeToday());
  const mins = Math.floor(remainingSec / 60);
  const secs = remainingSec % 60;
  display.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

  // 如果时间不足5分钟，变红
  if (remainingSec < 300) {
    display.style.color = '#EF5350';
  }
}

/** 清理资源（页面切换时调用） */
export function cleanupGame() {
  if (gameTimerInterval) {
    clearInterval(gameTimerInterval);
    gameTimerInterval = null;
  }
  cleanupActiveMiniGames();
}
