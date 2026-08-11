/**
 * 数据存储层 - localStorage 封装
 * @typedef {Object} Task
 * @property {string} id - 唯一标识
 * @property {string} title - 任务标题
 * @property {string} date - 日期 YYYY-MM-DD
 * @property {boolean} completed - 是否完成
 * @property {number} [count] - 次数模式：目标次数
 * @property {number} [duration] - 时间模式：目标时长(秒)
 * @property {string} [notes] - 学习心得
 * @property {number} [elapsed] - 已用时(秒)
 * @property {number} [currentCount] - 已完成次数
 * @property {number[]} [repeatDays] - 重复星期几 (0=周日, 1=周一, ..., 6=周六)，空数组表示不重复
 */

/**
 * @typedef {Object} CoinRecord
 * @property {string} date - 日期
 * @property {number} amount - 金币数量
 * @property {string} reason - 原因
 */

/**
 * @typedef {Object} AppState
 * @property {Task[]} tasks
 * @property {number} coins
 * @property {CoinRecord[]} coinRecords
 * @property {number} gameTimeToday
 * @property {number} streakDays
 * @property {string} lastActiveDate
 * @property {number} totalStudySeconds
 * @property {Object<string, number>} dailyStudySeconds - { "YYYY-MM-DD": seconds }
 * @property {Object<string, string[]>} dailyNotes - { "YYYY-MM-DD": ["note1","note2"] }
 */

const STORAGE_KEY = 'study_motivator_data';

/** @returns {AppState} */
function getDefaultState() {
  return {
    tasks: [],
    coins: 0,
    coinRecords: [],
    gameTimeToday: 0,
    streakDays: 0,
    lastActiveDate: '',
    totalStudySeconds: 0,
    dailyStudySeconds: {},
    dailyNotes: {},
    lastDailyBufferDate: '',    // 上次领取每日50金币buffer的日期
  };
}

/** 从 localStorage 加载数据 */
function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const data = JSON.parse(raw);
      // 检查日期，如果不是今天则重置游戏时间
      const today = getToday();
      if (data._lastGameDate !== today) {
        data.gameTimeToday = 0;
        data._lastGameDate = today;
      }
      return data;
    }
  } catch (e) {
    console.error('数据加载失败:', e);
  }
  const def = getDefaultState();
  def._lastGameDate = getToday();
  return def;
}

/** 保存数据到 localStorage */
function save(state) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (e) {
    console.error('数据保存失败:', e);
  }
}

/** 获取今天日期字符串 YYYY-MM-DD */
function getToday() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

/** 生成唯一ID */
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2, 5);
}

// ==================== 初始化 ====================
let state = load();

// ==================== 任务操作 ====================

/** 获取指定日期的任务 */
function getTasksByDate(date) {
  return state.tasks.filter(t => t.date === date);
}

/** 添加任务 */
function addTask(title, date, options = {}) {
  /** @type {Task} */
  const task = {
    id: generateId(),
    title,
    date: date || getToday(),
    completed: false,
    count: options.count || null,
    duration: options.duration || null,
    notes: '',
    elapsed: 0,
    currentCount: 0,
    repeatDays: options.repeatDays || [],
  };
  state.tasks.push(task);
  save(state);
  return task;
}

/** 更新任务 */
function updateTask(id, updates) {
  const idx = state.tasks.findIndex(t => t.id === id);
  if (idx !== -1) {
    state.tasks[idx] = { ...state.tasks[idx], ...updates };
    save(state);
    return state.tasks[idx];
  }
  return null;
}

/** 删除任务 */
function deleteTask(id) {
  state.tasks = state.tasks.filter(t => t.id !== id);
  save(state);
}

/** 切换任务完成状态 */
function toggleTaskComplete(id) {
  const task = state.tasks.find(t => t.id === id);
  if (task) {
    task.completed = !task.completed;
    save(state);
    return task;
  }
  return null;
}

// ==================== 金币操作 ====================

/** 获取当前金币数 */
function getCoins() {
  return state.coins;
}

/** 增加金币 */
function addCoins(amount, reason) {
  const today = getToday();

  state.coins += amount;
  state.coinRecords.push({ date: today, amount, reason });
  save(state);

  return amount;
}

/** 花费金币（返回实际花费金额） */
function spendCoins(amount, reason) {
  if (state.coins >= amount) {
    state.coins -= amount;
    const today = getToday();
    state.coinRecords.push({ date: today, amount: -amount, reason: reason || '花费金币' });
    save(state);
    return amount;
  }
  return 0;
}

/** 获取金币记录 */
function getCoinRecords() {
  return [...state.coinRecords];
}

// ==================== 打卡连续 ====================

/** 记录今日活跃（打卡） */
function recordActive() {
  const today = getToday();
  if (state.lastActiveDate === today) return;

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = `${yesterday.getFullYear()}-${String(yesterday.getMonth() + 1).padStart(2, '0')}-${String(yesterday.getDate()).padStart(2, '0')}`;

  if (state.lastActiveDate === yesterdayStr) {
    state.streakDays += 1;
  } else {
    state.streakDays = 1;
  }
  state.lastActiveDate = today;
  save(state);
}

/** 获取连续打卡天数 */
function getStreakDays() {
  return state.streakDays;
}

// ==================== 游戏时间 ====================

/** 获取今日游戏已用秒数 */
function getGameTimeToday() {
  const today = getToday();
  if (state._lastGameDate !== today) {
    state.gameTimeToday = 0;
    state._lastGameDate = today;
    save(state);
  }
  return state.gameTimeToday;
}

/** 增加游戏时间 */
function addGameTime(seconds) {
  const today = getToday();
  if (state._lastGameDate !== today) {
    state.gameTimeToday = 0;
    state._lastGameDate = today;
  }
  state.gameTimeToday += seconds;
  save(state);
}

// ==================== 学习时长 ====================

/** 增加总学习时长 */
function addStudyTime(seconds) {
  state.totalStudySeconds += seconds;
  // 记录每日学习时长
  const today = getToday();
  if (!state.dailyStudySeconds[today]) state.dailyStudySeconds[today] = 0;
  state.dailyStudySeconds[today] += seconds;
  save(state);
}

/** 获取总学习时长(秒) */
function getTotalStudyTime() {
  return state.totalStudySeconds;
}

/** 获取指定日期的学习时长(秒) */
function getDailyStudySeconds(date) {
  return state.dailyStudySeconds[date] || 0;
}

/** 获取最近N天的学习时长数组 [{date, seconds}, ...] */
function getRecentStudyDays(n) {
  const result = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    const dateStr = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    result.push({ date: dateStr, seconds: state.dailyStudySeconds[dateStr] || 0, label: ['日','一','二','三','四','五','六'][d.getDay()] });
  }
  return result;
}

/** 获取总完成任务数 */
function getTotalCompletedTasks() {
  return state.tasks.filter(t => t.completed).length;
}

// ==================== 学习心得 ====================

/** 添加学习心得到指定日期 */
function addNote(date, note) {
  if (!state.dailyNotes[date]) {
    state.dailyNotes[date] = [];
  }
  state.dailyNotes[date].push(note);
  save(state);
}

/** 获取指定日期的学习心得 */
function getNotes(date) {
  return state.dailyNotes[date] || [];
}

// ==================== 获取所有有任务的日期 ====================

/** 获取有任务记录的所有日期 */
function getDatesWithTasks() {
  const dates = new Set();
  state.tasks.forEach(t => dates.add(t.date));
  return dates;
}

/** 获取有已完成任务的日期 */
function getDatesWithCompletedTasks() {
  const dates = new Set();
  state.tasks.filter(t => t.completed).forEach(t => dates.add(t.date));
  return dates;
}

// ==================== 白噪音拥有状态 ====================

/** 获取已拥有的白噪音ID列表 */
function getOwnedWhiteNoises() {
  return state.ownedWhiteNoises || [];
}

/** 添加已拥有的白噪音 */
function addOwnedWhiteNoise(noiseId) {
  if (!state.ownedWhiteNoises) {
    state.ownedWhiteNoises = [];
  }
  if (!state.ownedWhiteNoises.includes(noiseId)) {
    state.ownedWhiteNoises.push(noiseId);
    save(state);
  }
}

// ========== 每日50金币buffer ==========
// 每次计时完成时调用，每天只能领一次
export function claimDailyBuffer() {
  const today = getToday();
  if (state.lastDailyBufferDate === today) {
    return { claimed: false, coins: 0 }; // 今天已经领过了
  }
  state.coins += 50;
  state.lastDailyBufferDate = today;
  save(state);
  return { claimed: true, coins: 50 };
}

// ==================== 导出 ====================

export const store = {
  // 原始状态（只读）
  getState: () => ({ ...state }),

  // 任务
  getTasksByDate,
  addTask,
  updateTask,
  deleteTask,
  toggleTaskComplete,

  // 金币
  getCoins,
  addCoins,
  spendCoins,
  claimDailyBuffer,
  getCoinRecords,

  // 打卡
  recordActive,
  getStreakDays,

  // 游戏时间
  getGameTimeToday,
  addGameTime,

  // 学习时长
  addStudyTime,
  getTotalStudyTime,
  getDailyStudySeconds,
  getRecentStudyDays,
  getTotalCompletedTasks,

  // 心得
  addNote,
  getNotes,

  // 日历
  getDatesWithTasks,
  getDatesWithCompletedTasks,

  // 白噪音
  getOwnedWhiteNoises,
  addOwnedWhiteNoise,

  // 每日buffer
  claimDailyBuffer,

  // 工具
  getToday,
};
