/**
 * 首页模块 - 任务管理 + 快捷入口
 */
import { store } from './store.js';
import { getTaskCheckboxImage, getQuoteDecorationImage, refreshDecorations } from './decoration-manager.js';

let editingTaskId = null;

/** 初始化首页 */
export function initHome() {
  renderHome();
}

/** 渲染首页内容 */
export function renderHome() {
  const page = document.getElementById('page-home');
  const today = store.getToday();
  const tasks = store.getTasksByDate(today);
  const coins = store.getCoins();
  const gameTime = store.getGameTimeToday();
  const completedCount = tasks.filter(t => t.completed).length;
  const totalCount = tasks.length;
  const allDone = totalCount > 0 && completedCount === totalCount;

  // 获取装饰图片
  const checkboxImg = getTaskCheckboxImage();
  const quoteDeco = getQuoteDecorationImage();

  // 检查是否有已完成任务（解锁游戏）
  const hasCompletedTask = completedCount > 0;
  const gameUnlocked = hasCompletedTask;
  const gameRemainSec = Math.max(0, 20 * 60 - gameTime);
  const gameRemainMin = Math.floor(gameRemainSec / 60);
  const gameRemainSecLeft = gameRemainSec % 60;

  page.innerHTML = `
    <!-- 每日激励语句 -->
    <div class="card motivation-banner" id="daily-quote">📖 加载中...${quoteDeco ? `<img class="quote-deco-img" src="${quoteDeco}" alt="">` : ''}</div>

    <!-- 今日待办 -->
    <div class="card task-section">
      <div class="section-header">
        <h3>📋 今日待办</h3>
        <span class="task-progress">${completedCount}/${totalCount}</span>
      </div>
      <div id="task-list">
        ${tasks.length === 0 ? '<div class="empty-hint">今天还没有任务，点击下方添加吧 ✨</div>' : ''}
        ${tasks.map(task => `
          <div class="task-item ${task.completed ? 'completed' : ''}" data-id="${task.id}">
            <div class="task-checkbox">
              ${checkboxImg 
                ? `<img class="checkbox-deco" src="${checkboxImg}" width="15" height="15" alt="" style="opacity:${task.completed ? 1 : 0.4};filter:${task.completed ? 'none' : 'grayscale(0.6)'}">`
                : (task.completed ? '✅' : '⬜')
              }
            </div>
            <div class="task-info">
              <span class="task-title">${escapeHtml(task.title)}</span>
              ${task.duration ? `<span class="task-meta">⏱ ${Math.floor(task.duration / 60)}分钟</span>` : ''}
              ${task.count ? `<span class="task-meta">🔢 ${task.count}次</span>` : ''}
            </div>
            <div class="task-actions">
              <button class="btn-icon" data-action="edit" data-id="${task.id}" title="编辑">✏️</button>
              <button class="btn-icon" data-action="delete" data-id="${task.id}" title="删除">🗑️</button>
            </div>
          </div>
        `).join('')}
      </div>
      <button class="btn-add-task" id="btn-add-task">+ 添加任务</button>
    </div>

    <!-- 快捷计时入口 -->
    <button class="btn-primary btn-timer-entry" id="btn-quick-timer" ${tasks.length === 0 ? 'disabled' : ''}>
      ⏱ 开始计时学习
    </button>

    <!-- 解压游戏入口 -->
    <div class="card game-entry-card">
      <div class="game-entry-header">
        <span>🎮 解压游戏</span>
        ${gameUnlocked
          ? `<span class="game-time-remain">剩余 ${gameRemainMin}:${String(gameRemainSecLeft).padStart(2, '0')}</span>`
          : '<span class="game-locked">完成1个任务解锁 🔒</span>'
        }
      </div>
      <button class="btn-secondary" id="btn-go-game" ${!gameUnlocked ? 'disabled' : ''}>
        ${gameUnlocked ? '进入游戏 →' : '完成任务后解锁'}
      </button>
    </div>

    <!-- 金币余额 -->
    <div class="coin-display">
      💰 ${coins} 金币
      ${allDone ? '<div class="bonus-hint">🎉 今日任务全部完成！</div>' : ''}
    </div>
  `;

  // 设置激励语句（保留横幅内的装饰图片）
  setDailyQuote(quoteDeco);

  // 绑定事件
  bindHomeEvents();

  // 重渲染后重新注入首页装饰（小鱼干/爪印勾选框）
  refreshDecorations();
}

/** 绑定首页事件 */
function bindHomeEvents() {
  // 任务点击切换完成状态
  document.querySelectorAll('.task-item').forEach(el => {
    el.addEventListener('click', (e) => {
      // 如果点击的是编辑或删除按钮，不切换完成状态
      if (e.target.closest('[data-action="edit"]') || e.target.closest('[data-action="delete"]')) {
        return;
      }
      const id = el.dataset.id;
      const task = store.toggleTaskComplete(id);
      if (task) {
        // 检查是否所有任务都完成了
        const tasks = store.getTasksByDate(store.getToday());
        const completedCount = tasks.filter(t => t.completed).length;
        const totalCount = tasks.length;
        const allDone = totalCount > 0 && completedCount === totalCount;
        
        if (allDone) {
          // 领取每日50金币buffer
          const result = store.claimDailyBuffer();
          if (result.claimed) {
            setTimeout(() => {
              alert(`🎉 恭喜！今日任务全部完成！获得 ${result.coins} 金币奖励！`);
            }, 300);
          }
        }
        
        renderHome();
      }
    });
  });

  // 任务编辑
  document.querySelectorAll('[data-action="edit"]').forEach(el => {
    el.addEventListener('click', () => {
      const id = el.dataset.id;
      showEditDialog(id);
    });
  });

  // 任务删除
  document.querySelectorAll('[data-action="delete"]').forEach(el => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      const id = el.dataset.id;
      if (confirm('确定删除这个任务吗？')) {
        store.deleteTask(id);
        renderHome();
      }
    });
  });

  // 添加任务
  const btnAdd = document.getElementById('btn-add-task');
  if (btnAdd) {
    btnAdd.addEventListener('click', () => showAddDialog());
  }

  // 快捷计时按钮
  const btnTimer = document.getElementById('btn-quick-timer');
  if (btnTimer) {
    btnTimer.addEventListener('click', () => {
      // 切换到计时Tab
      switchTab('page-timer');
    });
  }

  // 游戏入口
  const btnGame = document.getElementById('btn-go-game');
  if (btnGame) {
    btnGame.addEventListener('click', () => {
      if (!btnGame.disabled) {
        switchTab('page-game');
      }
    });
  }
}

/** 显示添加任务对话框 */
function showAddDialog() {
  const overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.innerHTML = `
    <div class="dialog">
      <h3>添加新任务</h3>
      <div class="form-group">
        <label>任务名称</label>
        <input type="text" id="input-task-title" placeholder="例如：数学作业" maxlength="30" autofocus>
      </div>
      <div class="form-group">
        <label>计时模式</label>
        <select id="input-task-mode">
          <option value="none">不计时</option>
          <option value="time">时间模式（分钟）</option>
          <option value="count">次数模式</option>
        </select>
      </div>
      <div class="form-group" id="group-time" style="display:none">
        <label>目标时长（分钟）</label>
        <input type="number" id="input-task-time" min="1" max="240" value="30">
      </div>
      <div class="form-group" id="group-count" style="display:none">
        <label>目标次数</label>
        <input type="number" id="input-task-count" min="1" max="999" value="10">
      </div>
      <div class="dialog-buttons">
        <button class="btn-secondary" id="btn-cancel-add">取消</button>
        <button class="btn-primary" id="btn-confirm-add">添加</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  // 模式切换
  const modeSelect = document.getElementById('input-task-mode');
  modeSelect.addEventListener('change', () => {
    document.getElementById('group-time').style.display = modeSelect.value === 'time' ? '' : 'none';
    document.getElementById('group-count').style.display = modeSelect.value === 'count' ? '' : 'none';
  });

  // 取消
  document.getElementById('btn-cancel-add').addEventListener('click', () => {
    overlay.remove();
  });

  // 确认添加
  document.getElementById('btn-confirm-add').addEventListener('click', () => {
    const title = document.getElementById('input-task-title').value.trim();
    if (!title) {
      alert('请输入任务名称');
      return;
    }
    const mode = modeSelect.value;
    const options = {};
    if (mode === 'time') {
      options.duration = parseInt(document.getElementById('input-task-time').value) * 60;
    } else if (mode === 'count') {
      options.count = parseInt(document.getElementById('input-task-count').value);
    }
    store.addTask(title, store.getToday(), options);
    overlay.remove();
    renderHome();
  });

  // 点击遮罩关闭
  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });

  // 回车确认
  document.getElementById('input-task-title').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') document.getElementById('btn-confirm-add').click();
  });
}

/** 显示编辑任务对话框 */
function showEditDialog(taskId) {
  const tasks = store.getTasksByDate(store.getToday());
  const task = tasks.find(t => t.id === taskId);
  if (!task) return;

  const overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.innerHTML = `
    <div class="dialog">
      <h3>编辑任务</h3>
      <div class="form-group">
        <label>任务名称</label>
        <input type="text" id="input-edit-title" value="${escapeHtml(task.title)}" maxlength="30">
      </div>
      <div class="dialog-buttons">
        <button class="btn-secondary" id="btn-cancel-edit">取消</button>
        <button class="btn-primary" id="btn-confirm-edit">保存</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  document.getElementById('btn-cancel-edit').addEventListener('click', () => overlay.remove());

  document.getElementById('btn-confirm-edit').addEventListener('click', () => {
    const title = document.getElementById('input-edit-title').value.trim();
    if (!title) {
      alert('请输入任务名称');
      return;
    }
    store.updateTask(taskId, { title });
    overlay.remove();
    renderHome();
  });

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });
}

/** 设置每日激励语句（保留装饰图片） */
function setDailyQuote(quoteDeco) {
  const quotes = [
    "今天的努力，是明天的底气！",
    "学如逆水行舟，不进则退。",
    "每一小步，都是大进步！",
    "坚持就是胜利，加油！",
    "知识就是力量，学习成就未来！",
    "不怕慢，只怕站。",
    "你今天的学习，决定了明天的选择。",
    "努力不一定成功，但放弃一定失败。",
    "把每一次作业当作一次成长的机会。",
    "今天的汗水，是明天的微笑！",
    "好好学习，天天向上！",
    "书山有路勤为径，学海无涯苦作舟。",
    "成功 = 努力 + 坚持 + 方法。",
    "越努力，越幸运！",
    "学习是一次没有终点的旅行。",
    "不要害怕失败，要害怕没有尝试。",
    "每天进步一点点，终将遇见更好的自己。",
    "你的未来，藏在你现在的努力里。",
    "勤奋是好运之母。",
    "心有多大，舞台就有多大。",
    "少壮不努力，老大徒伤悲。",
    "千里之行，始于足下。",
    "天才在于积累，聪明在于勤奋。",
    "世上无难事，只要肯攀登。",
    "宝剑锋从磨砺出，梅花香自苦寒来。",
    "读万卷书，行万里路。",
    "活到老，学到老。",
    "知识改变命运，学习成就未来。",
    "一分耕耘，一分收获。",
    "只要功夫深，铁杵磨成针。",
    "积少成多，集腋成裘。",
  ];
  const today = new Date();
  const dayOfYear = Math.floor((today - new Date(today.getFullYear(), 0, 0)) / 86400000);
  const quote = quotes[dayOfYear % quotes.length];
  const el = document.getElementById('daily-quote');
  if (el) {
    el.innerHTML = '📖 ' + escapeHtml(quote) +
      (quoteDeco ? `<img class="quote-deco-img" src="${quoteDeco}" alt="">` : '');
  }
}

/** 切换Tab */
function switchTab(pageId) {
  document.querySelectorAll('.tab-item').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelector(`[data-page="${pageId}"]`).classList.add('active');
  document.getElementById(pageId).classList.add('active');

  // 切换到计时页时触发渲染
  if (pageId === 'page-timer') {
    import('./timer.js').then(m => m.renderTimerPage());
  }
}

/** HTML转义 */
function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}
