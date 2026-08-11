/**
 * 日历页模块 - 月历视图 + 日期任务管理
 */
import { store } from './store.js';
import { refreshDecorations } from './decoration-manager.js';

let currentYear = new Date().getFullYear();
let currentMonth = new Date().getMonth(); // 0-11

/** 初始化日历页 */
export function initCalendar() {
  renderCalendar();
}

/** 渲染日历 */
export function renderCalendar() {
  const page = document.getElementById('page-calendar');
  const today = store.getToday();
  const datesWithTasks = store.getDatesWithTasks();
  const datesCompleted = store.getDatesWithCompletedTasks();

  // 月份标题
  const monthNames = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月'];

  // 计算日历数据
  const firstDay = new Date(currentYear, currentMonth, 1);
  const lastDay = new Date(currentYear, currentMonth + 1, 0);
  const startWeekday = firstDay.getDay(); // 0=周日
  const totalDays = lastDay.getDate();

  // 生成日历格子
  let cells = '';
  // 空白填充（月初前的空白）
  for (let i = 0; i < startWeekday; i++) {
    cells += '<div class="calendar-cell empty"></div>';
  }
  // 日期格子
  for (let day = 1; day <= totalDays; day++) {
    const dateStr = `${currentYear}-${String(currentMonth + 1).padStart(2, '0')}-${String(day).padStart(2, '0')}`;
    const isToday = dateStr === today;
    const hasTask = datesWithTasks.has(dateStr);
    const isCompleted = datesCompleted.has(dateStr);

    let classes = 'calendar-cell';
    if (isToday) classes += ' today';
    if (isCompleted) classes += ' checked';

    cells += `
      <div class="${classes}" data-date="${dateStr}">
        <span class="cell-day">${day}</span>
        ${hasTask ? '<span class="cell-dot"></span>' : ''}
        ${isCompleted ? '<span class="cell-check">✓</span>' : ''}
      </div>
    `;
  }

  page.innerHTML = `
    <div class="calendar-header">
      <button class="btn-icon" id="btn-prev-month">◀</button>
      <h3 class="calendar-title">${currentYear}年 ${monthNames[currentMonth]}</h3>
      <button class="btn-icon" id="btn-next-month">▶</button>
    </div>
    <div class="calendar-weekdays">
      <span>日</span><span>一</span><span>二</span><span>三</span><span>四</span><span>五</span><span>六</span>
    </div>
    <div class="calendar-grid">
      ${cells}
    </div>
    <div class="calendar-legend">
      <span class="legend-item"><span class="legend-dot dot-task"></span> 有任务</span>
      <span class="legend-item"><span class="legend-dot dot-done"></span> 已打卡</span>
      <span class="legend-item"><span class="legend-dot dot-today"></span> 今天</span>
    </div>
    <div id="day-detail-panel" class="card day-detail-panel" style="display:none"></div>
  `;

  bindCalendarEvents();
  // 重渲染后重新注入日历页装饰（熊头/猫头/贝壳/蝙蝠）
  refreshDecorations();
}

/** 绑定日历事件 */
function bindCalendarEvents() {
  // 上一个月
  document.getElementById('btn-prev-month').addEventListener('click', () => {
    currentMonth--;
    if (currentMonth < 0) {
      currentMonth = 11;
      currentYear--;
    }
    renderCalendar();
  });

  // 下一个月
  document.getElementById('btn-next-month').addEventListener('click', () => {
    currentMonth++;
    if (currentMonth > 11) {
      currentMonth = 0;
      currentYear++;
    }
    renderCalendar();
  });

  // 点击日期格子
  document.querySelectorAll('.calendar-cell:not(.empty)').forEach(cell => {
    cell.addEventListener('click', () => {
      const date = cell.dataset.date;
      showDayDetail(date);
    });
  });
}

/** 显示日期详情面板 */
function showDayDetail(date) {
  const panel = document.getElementById('day-detail-panel');
  const tasks = store.getTasksByDate(date);
  const notes = store.getNotes(date);
  const dateObj = new Date(date + 'T00:00:00');
  const dateLabel = `${dateObj.getMonth() + 1}月${dateObj.getDate()}日`;

  let tasksHtml = tasks.length === 0
    ? '<div class="empty-hint">这天没有任务</div>'
    : tasks.map(t => {
      const repeatLabel = t.repeatDays && t.repeatDays.length > 0
        ? `<span class="task-repeat">🔁 ${t.repeatDays.map(d => ['日','一','二','三','四','五','六'][d]).join('')}</span>`
        : '';
      return `
      <div class="task-item ${t.completed ? 'completed' : ''}" data-task-id="${t.id}">
        <span class="task-checkbox" data-action="toggle" data-task-id="${t.id}">${t.completed ? '✅' : '⬜'}</span>
        <span class="task-title">${escapeHtml(t.title)}${repeatLabel}</span>
        <div class="task-actions">
          <button class="task-action-btn" data-action="edit" data-task-id="${t.id}" title="编辑">✏️</button>
          <button class="task-action-btn" data-action="delete" data-task-id="${t.id}" title="删除">🗑️</button>
        </div>
      </div>
    `;
    }).join('');

  let notesHtml = notes.length === 0
    ? '<div class="empty-hint">暂无学习心得</div>'
    : notes.map(n => `<div class="note-item">📝 ${escapeHtml(n)}</div>`).join('');

  panel.style.display = '';
  panel.innerHTML = `
    <div class="day-detail-header">
      <h3>${dateLabel} 的任务</h3>
      <button class="btn-icon" id="btn-close-detail">✕</button>
    </div>
    <div class="day-tasks">
      ${tasksHtml}
      <button class="btn-add-task btn-small" id="btn-add-day-task">+ 添加任务</button>
    </div>
    <div class="day-notes">
      <h4>📝 学习心得</h4>
      ${notesHtml}
    </div>
  `;

  // 关闭面板
  document.getElementById('btn-close-detail').addEventListener('click', () => {
    panel.style.display = 'none';
  });

  // 添加任务
  document.getElementById('btn-add-day-task').addEventListener('click', () => {
    showAddTaskForDate(date);
  });

  // 任务操作（切换完成、编辑、删除）
  panel.querySelectorAll('[data-action]').forEach(el => {
    el.addEventListener('click', (e) => {
      e.stopPropagation();
      const action = el.dataset.action;
      const taskId = el.dataset.taskId;
      if (action === 'toggle') {
        store.toggleTaskComplete(taskId);
        showDayDetail(date);
        renderCalendar();
      } else if (action === 'edit') {
        const task = store.getState().tasks.find(t => t.id === taskId);
        if (task) showEditTaskDialog(task, date);
      } else if (action === 'delete') {
        const task = store.getState().tasks.find(t => t.id === taskId);
        if (task) showDeleteConfirm(task, date);
      }
    });
  });
}

/** 删除确认弹窗 */
function showDeleteConfirm(task, date) {
  const isRepeat = task.repeatDays && task.repeatDays.length > 0;
  const overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.innerHTML = `
    <div class="dialog">
      <h3>删除任务</h3>
      <p style="color:var(--text-secondary);font-size:14px;margin:12px 0;">
        确定要删除「${escapeHtml(task.title)}」吗？
      </p>
      ${isRepeat ? `
        <div class="delete-repeat-options">
          <button class="btn-secondary btn-block" id="btn-delete-this">仅删除这一次</button>
          <button class="btn-danger btn-block" id="btn-delete-all">删除所有重复任务</button>
        </div>
      ` : ''}
      <div class="dialog-buttons">
        <button class="btn-secondary" id="btn-delete-cancel">取消</button>
        ${!isRepeat ? '<button class="btn-danger" id="btn-delete-confirm">删除</button>' : ''}
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  const close = () => overlay.remove();

  document.getElementById('btn-delete-cancel').addEventListener('click', close);

  if (!isRepeat) {
    document.getElementById('btn-delete-confirm').addEventListener('click', () => {
      store.deleteTask(task.id);
      close();
      renderCalendar();
      showDayDetail(date);
    });
  } else {
    // 仅删除这一次
    document.getElementById('btn-delete-this').addEventListener('click', () => {
      store.deleteTask(task.id);
      close();
      renderCalendar();
      showDayDetail(date);
    });
    // 删除所有重复任务
    document.getElementById('btn-delete-all').addEventListener('click', () => {
      // 找到所有相同标题且相同repeatDays的任务
      const allTasks = store.getState().tasks;
      const repeatGroup = allTasks.filter(t =>
        t.title === task.title &&
        t.repeatDays && t.repeatDays.length > 0 &&
        JSON.stringify(t.repeatDays) === JSON.stringify(task.repeatDays)
      );
      repeatGroup.forEach(t => store.deleteTask(t.id));
      close();
      renderCalendar();
      showDayDetail(date);
    });
  }

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) close();
  });
}

/** 编辑任务弹窗 */
function showEditTaskDialog(task, date) {
  const isRepeat = task.repeatDays && task.repeatDays.length > 0;
  const dayNames = ['日', '一', '二', '三', '四', '五', '六'];

  // 确定计时模式
  let currentMode = 'none';
  if (task.duration) currentMode = 'time';
  else if (task.count) currentMode = 'count';

  const overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.innerHTML = `
    <div class="dialog">
      <h3>编辑任务</h3>
      <div class="form-group">
        <label>任务名称</label>
        <input type="text" id="input-edit-task-title" value="${escapeHtml(task.title)}" maxlength="30" autofocus>
      </div>
      <div class="form-group">
        <label>计时模式</label>
        <select id="input-edit-task-mode">
          <option value="none" ${currentMode === 'none' ? 'selected' : ''}>不计时</option>
          <option value="time" ${currentMode === 'time' ? 'selected' : ''}>时间模式（分钟）</option>
          <option value="count" ${currentMode === 'count' ? 'selected' : ''}>次数模式</option>
        </select>
      </div>
      <div class="form-group" id="edit-group-time" style="display:${currentMode === 'time' ? '' : 'none'}">
        <label>目标时长（分钟）</label>
        <input type="number" id="input-edit-task-time" min="1" max="240" value="${task.duration ? Math.round(task.duration / 60) : 30}">
      </div>
      <div class="form-group" id="edit-group-count" style="display:${currentMode === 'count' ? '' : 'none'}">
        <label>目标次数</label>
        <input type="number" id="input-edit-task-count" min="1" max="999" value="${task.count || 10}">
      </div>
      <div class="form-group">
        <label>重复</label>
        <div class="repeat-selector">
          <div class="repeat-option ${!isRepeat ? 'active' : ''}" data-repeat="none">不重复</div>
          <div class="repeat-weekdays">
            ${[1,2,3,4,5,6,0].map(d => `
              <div class="weekday-chip ${(task.repeatDays || []).includes(d) ? 'active' : ''}" data-day="${d}">${dayNames[d]}</div>
            `).join('')}
          </div>
        </div>
      </div>
      ${isRepeat ? `
        <div class="edit-repeat-scope">
          <label style="font-size:12px;color:var(--text-secondary);">修改范围</label>
          <div class="scope-options">
            <button class="scope-btn active" data-scope="this">仅这一次</button>
            <button class="scope-btn" data-scope="all">所有重复任务</button>
          </div>
        </div>
      ` : ''}
      <div class="dialog-buttons">
        <button class="btn-secondary" id="btn-edit-cancel">取消</button>
        <button class="btn-primary" id="btn-edit-confirm">保存</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  const modeSelect = document.getElementById('input-edit-task-mode');
  modeSelect.addEventListener('change', () => {
    document.getElementById('edit-group-time').style.display = modeSelect.value === 'time' ? '' : 'none';
    document.getElementById('edit-group-count').style.display = modeSelect.value === 'count' ? '' : 'none';
  });

  // 重复选择逻辑
  const repeatNone = overlay.querySelector('[data-repeat="none"]');
  const weekdayChips = overlay.querySelectorAll('.weekday-chip');
  let selectedDays = [...(task.repeatDays || [])];

  repeatNone.addEventListener('click', () => {
    repeatNone.classList.add('active');
    weekdayChips.forEach(chip => chip.classList.remove('active'));
    selectedDays = [];
  });

  weekdayChips.forEach(chip => {
    chip.addEventListener('click', () => {
      chip.classList.toggle('active');
      const day = parseInt(chip.dataset.day);
      if (chip.classList.contains('active')) {
        if (!selectedDays.includes(day)) selectedDays.push(day);
      } else {
        selectedDays = selectedDays.filter(d => d !== day);
      }
      if (selectedDays.length > 0) {
        repeatNone.classList.remove('active');
      } else {
        repeatNone.classList.add('active');
      }
    });
  });

  // 修改范围选择
  let editScope = 'this';
  const scopeBtns = overlay.querySelectorAll('.scope-btn');
  scopeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      scopeBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      editScope = btn.dataset.scope;
    });
  });

  const close = () => overlay.remove();
  document.getElementById('btn-edit-cancel').addEventListener('click', close);

  document.getElementById('btn-edit-confirm').addEventListener('click', () => {
    const title = document.getElementById('input-edit-task-title').value.trim();
    if (!title) {
      alert('请输入任务名称');
      return;
    }
    const mode = modeSelect.value;
    const updates = {
      title,
      duration: mode === 'time' ? parseInt(document.getElementById('input-edit-task-time').value) * 60 : null,
      count: mode === 'count' ? parseInt(document.getElementById('input-edit-task-count').value) : null,
      repeatDays: selectedDays,
    };

    if (isRepeat && editScope === 'all') {
      // 修改所有重复任务
      const allTasks = store.getState().tasks;
      const repeatGroup = allTasks.filter(t =>
        t.title === task.title &&
        t.repeatDays && t.repeatDays.length > 0 &&
        JSON.stringify([...t.repeatDays].sort()) === JSON.stringify([...task.repeatDays].sort())
      );
      repeatGroup.forEach(t => store.updateTask(t.id, updates));
    } else {
      // 仅修改这一次
      store.updateTask(task.id, updates);
    }

    close();
    renderCalendar();
    showDayDetail(date);
  });

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) close();
  });

  document.getElementById('input-edit-task-title').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') document.getElementById('btn-edit-confirm').click();
  });
}

/** 为指定日期添加任务 */
function showAddTaskForDate(date) {
  const overlay = document.createElement('div');
  overlay.className = 'dialog-overlay';
  overlay.innerHTML = `
    <div class="dialog">
      <h3>添加任务</h3>
      <div class="form-group">
        <label>任务名称</label>
        <input type="text" id="input-cal-task-title" placeholder="例如：英语单词" maxlength="30" autofocus>
      </div>
      <div class="form-group">
        <label>计时模式</label>
        <select id="input-cal-task-mode">
          <option value="none">不计时</option>
          <option value="time">时间模式（分钟）</option>
          <option value="count">次数模式</option>
        </select>
      </div>
      <div class="form-group" id="cal-group-time" style="display:none">
        <label>目标时长（分钟）</label>
        <input type="number" id="input-cal-task-time" min="1" max="240" value="30">
      </div>
      <div class="form-group" id="cal-group-count" style="display:none">
        <label>目标次数</label>
        <input type="number" id="input-cal-task-count" min="1" max="999" value="10">
      </div>
      <div class="form-group">
        <label>重复</label>
        <div class="repeat-selector">
          <div class="repeat-option active" data-repeat="none">不重复</div>
          <div class="repeat-weekdays">
            <div class="weekday-chip" data-day="1">一</div>
            <div class="weekday-chip" data-day="2">二</div>
            <div class="weekday-chip" data-day="3">三</div>
            <div class="weekday-chip" data-day="4">四</div>
            <div class="weekday-chip" data-day="5">五</div>
            <div class="weekday-chip" data-day="6">六</div>
            <div class="weekday-chip" data-day="0">日</div>
          </div>
        </div>
      </div>
      <div class="dialog-buttons">
        <button class="btn-secondary" id="btn-cal-cancel">取消</button>
        <button class="btn-primary" id="btn-cal-confirm">添加</button>
      </div>
    </div>
  `;
  document.body.appendChild(overlay);

  const modeSelect = document.getElementById('input-cal-task-mode');
  modeSelect.addEventListener('change', () => {
    document.getElementById('cal-group-time').style.display = modeSelect.value === 'time' ? '' : 'none';
    document.getElementById('cal-group-count').style.display = modeSelect.value === 'count' ? '' : 'none';
  });

  // 重复选择逻辑
  const repeatNone = overlay.querySelector('[data-repeat="none"]');
  const weekdayChips = overlay.querySelectorAll('.weekday-chip');
  let selectedDays = [];

  repeatNone.addEventListener('click', () => {
    repeatNone.classList.add('active');
    weekdayChips.forEach(chip => chip.classList.remove('active'));
    selectedDays = [];
  });

  weekdayChips.forEach(chip => {
    chip.addEventListener('click', () => {
      chip.classList.toggle('active');
      const day = parseInt(chip.dataset.day);
      if (chip.classList.contains('active')) {
        if (!selectedDays.includes(day)) selectedDays.push(day);
      } else {
        selectedDays = selectedDays.filter(d => d !== day);
      }
      // 如果选择了星期，取消"不重复"
      if (selectedDays.length > 0) {
        repeatNone.classList.remove('active');
      } else {
        repeatNone.classList.add('active');
      }
    });
  });

  document.getElementById('btn-cal-cancel').addEventListener('click', () => overlay.remove());

  document.getElementById('btn-cal-confirm').addEventListener('click', () => {
    const title = document.getElementById('input-cal-task-title').value.trim();
    if (!title) {
      alert('请输入任务名称');
      return;
    }
    const mode = modeSelect.value;
    const options = {};
    if (mode === 'time') {
      options.duration = parseInt(document.getElementById('input-cal-task-time').value) * 60;
    } else if (mode === 'count') {
      options.count = parseInt(document.getElementById('input-cal-task-count').value);
    }

    if (selectedDays.length > 0) {
      // 有重复：为每个匹配的日期创建任务实例（当前月+下个月）
      options.repeatDays = selectedDays;
      const startDate = new Date(date + 'T00:00:00');
      const endDate = new Date(startDate);
      endDate.setMonth(endDate.getMonth() + 2); // 生成未来2个月的任务

      const datesToCreate = [];
      const current = new Date(startDate);
      while (current <= endDate) {
        const dayOfWeek = current.getDay();
        if (selectedDays.includes(dayOfWeek)) {
          const dateStr = `${current.getFullYear()}-${String(current.getMonth() + 1).padStart(2, '0')}-${String(current.getDate()).padStart(2, '0')}`;
          datesToCreate.push(dateStr);
        }
        current.setDate(current.getDate() + 1);
      }

      datesToCreate.forEach(d => {
        store.addTask(title, d, { ...options, repeatDays: selectedDays });
      });
    } else {
      // 不重复：只创建当天任务
      store.addTask(title, date, options);
    }

    overlay.remove();
    renderCalendar();
    // 刷新详情面板
    showDayDetail(date);
  });

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });

  document.getElementById('input-cal-task-title').addEventListener('keydown', (e) => {
    if (e.key === 'Enter') document.getElementById('btn-cal-confirm').click();
  });
}

/** HTML转义 */
function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str;
  return div.innerHTML;
}
