/**
 * 主题管理模块 - 主题切换、衣柜混搭、购买、持久化
 */
import { THEMES, getThemeById, getAccessoriesByDimension, calcThemeBundlePrice, getDecorationImage, WARDROBE_DIMENSIONS, TIERS } from './themes.js';
import { store } from './store.js';

const THEME_KEY = 'studyRecorder_theme';
const OWNED_KEY = 'studyRecorder_ownedThemes';
const OWNED_ACC_KEY = 'studyRecorder_ownedAccessories';
const WARDROBE_KEY = 'studyRecorder_wardrobe';

let currentThemeId = 'wood';

// ========== 初始化 ==========

/** 初始化：从localStorage读取主题和衣柜 */
export function initTheme() {
  const saved = localStorage.getItem(THEME_KEY);
  if (saved) currentThemeId = saved;
  // 应用衣柜状态（支持混搭）
  applyWardrobe();
}

// ========== 主题查询 ==========

export function getCurrentTheme() { return getThemeById(currentThemeId); }
export function getCurrentThemeId() { return currentThemeId; }
export function getAllThemes() { return THEMES; }
export function getTiers() { return TIERS; }
export function getDimensions() { return WARDROBE_DIMENSIONS; }

// ========== 拥有状态 ==========

export function getOwnedThemes() {
  try {
    const owned = localStorage.getItem(OWNED_KEY);
    if (owned) return JSON.parse(owned);
  } catch (e) { /* ignore */ }
  return THEMES.filter(t => t.tier === 'default').map(t => t.id);
}

export function isThemeOwned(themeId) {
  return getOwnedThemes().includes(themeId);
}

/** 获取已拥有的配饰列表 [{themeId, dimId}, ...] */
export function getOwnedAccessories() {
  try {
    const acc = localStorage.getItem(OWNED_ACC_KEY);
    if (acc) return JSON.parse(acc);
  } catch (e) { /* ignore */ }
  // 默认拥有默认主题的全部配饰
  const defaultTheme = THEMES.find(t => t.tier === 'default');
  if (defaultTheme) {
    return Object.keys(defaultTheme.accessories).map(dimId => ({ themeId: defaultTheme.id, dimId }));
  }
  return [];
}

export function isAccessoryOwned(themeId, dimId) {
  return getOwnedAccessories().some(a => a.themeId === themeId && a.dimId === dimId);
}

// ========== 衣柜 ==========

/** 获取当前衣柜状态 { font: themeId, calendar: themeId, ... }（带校验，非法值回退默认） */
export function getWardrobe() {
  let saved = {};
  try {
    const wb = localStorage.getItem(WARDROBE_KEY);
    if (wb) saved = JSON.parse(wb);
  } catch (e) { /* ignore */ }
  const defaultTheme = THEMES.find(t => t.tier === 'default');
  const defaultId = defaultTheme?.id || 'wood';
  const wb = {};
  WARDROBE_DIMENSIONS.forEach(dim => {
    const candidate = saved[dim.id];
    // 校验：必须是真实存在且拥有该维度配饰的主题，否则回退默认
    const theme = candidate ? getThemeById(candidate) : null;
    wb[dim.id] = (theme && theme.id === candidate && theme.accessories[dim.id]) ? candidate : defaultId;
  });
  return wb;
}

function saveWardrobe(wb) {
  localStorage.setItem(WARDROBE_KEY, JSON.stringify(wb));
}

/** 装备配饰（某个维度切换到某个主题的配饰，仅影响该维度） */
export function equipAccessory(dimId, themeId) {
  if (!isAccessoryOwned(themeId, dimId)) {
    return { success: false, message: '请先购买该配饰' };
  }
  const wb = getWardrobe();
  wb[dimId] = themeId;
  saveWardrobe(wb);
  applyWardrobe();
  return { success: true, message: '已装备' };
}

/** 整套装备（已拥有主题的全部配饰一次性穿上） */
export function equipThemeFull(themeId) {
  const theme = getThemeById(themeId);
  if (!theme || !isThemeOwned(themeId)) {
    return { success: false, message: '请先购买该主题' };
  }
  const wb = getWardrobe();
  Object.keys(theme.accessories).forEach(dimId => { wb[dimId] = themeId; });
  saveWardrobe(wb);
  currentThemeId = themeId;
  localStorage.setItem(THEME_KEY, themeId);
  applyWardrobe();
  return { success: true, message: `已整套装备「${theme.name}」` };
}

/** 获取某个维度当前装备的主题 */
export function getEquippedTheme(dimId) {
  const wb = getWardrobe();
  return getThemeById(wb[dimId] || 'wood');
}

// ========== 购买 ==========

/** 计算整主题剩余应付价：整主题折扣价 − 已单买配饰金额（总花费永不超过整主题价） */
export function getRemainingBundleInfo(themeId) {
  const theme = getThemeById(themeId);
  const dims = Object.keys(theme.accessories);
  const ownedCount = dims.filter(dimId => isAccessoryOwned(themeId, dimId)).length;
  const remaining = dims.length - ownedCount;
  const tierPrices = { default: 0, normal: 50, advanced: 80, high: 120, top: 170, legend: 250 };
  const singlePrice = tierPrices[theme.tier] || 50;
  const fullPrice = calcThemeBundlePrice(theme);
  const price = Math.max(0, fullPrice - ownedCount * singlePrice);
  return { total: dims.length, ownedCount, remaining, singlePrice, fullPrice, price };
}

/** 购买整主题（剩余配饰，已单买的部分不重复收费） */
export function purchaseTheme(themeId) {
  const theme = getThemeById(themeId);
  if (!theme) return { success: false, message: '主题不存在' };
  if (isThemeOwned(themeId)) return { success: false, message: '已拥有该主题' };
  if (!theme.available) return { success: false, message: '即将上线' };

  const info = getRemainingBundleInfo(themeId);
  const price = info.price;
  const coins = store.getCoins();
  if (coins < price) {
    return { success: false, message: `金币不足！需要 ${price} 金币，当前 ${coins} 金币` };
  }

  if (price > 0) {
    const spent = store.spendCoins(price, `购买主题：${theme.name}（剩余${info.remaining}件配饰）`);
    if (spent <= 0) return { success: false, message: '金币不足，购买失败' };
  }

  // 记录拥有
  const owned = getOwnedThemes();
  owned.push(themeId);
  localStorage.setItem(OWNED_KEY, JSON.stringify(owned));

  // 记录拥有配饰
  const ownedAcc = getOwnedAccessories();
  Object.keys(theme.accessories).forEach(dimId => {
    if (!ownedAcc.some(a => a.themeId === themeId && a.dimId === dimId)) {
      ownedAcc.push({ themeId, dimId });
    }
  });
  localStorage.setItem(OWNED_ACC_KEY, JSON.stringify(ownedAcc));

  // 自动装备所有配饰到衣柜
  const wb = getWardrobe();
  Object.keys(theme.accessories).forEach(dimId => { wb[dimId] = themeId; });
  saveWardrobe(wb);

  applyWardrobe();
  return { success: true, message: `购买成功！「${theme.name}」已装备到衣柜`, theme, price };
}

/** 单独购买某个维度的配饰 */
export function purchaseAccessory(themeId, dimId) {
  const theme = getThemeById(themeId);
  if (!theme) return { success: false, message: '主题不存在' };
  if (isAccessoryOwned(themeId, dimId)) return { success: false, message: '已拥有该配饰' };
  if (!theme.available) return { success: false, message: '即将上线' };

  const tierPrices = { default: 0, normal: 50, advanced: 80, high: 120, top: 170, legend: 250 };
  const price = tierPrices[theme.tier] || 50;
  const coins = store.getCoins();
  if (coins < price) {
    return { success: false, message: `金币不足！需要 ${price} 金币，当前 ${coins} 金币` };
  }

  const dimName = WARDROBE_DIMENSIONS.find(d => d.id === dimId)?.name || dimId;
  const spent = store.spendCoins(price, `购买配饰：${theme.name}·${dimName}`);
  if (spent <= 0) return { success: false, message: '金币不足，购买失败' };

  const ownedAcc = getOwnedAccessories();
  ownedAcc.push({ themeId, dimId });
  localStorage.setItem(OWNED_ACC_KEY, JSON.stringify(ownedAcc));

  // 自动装备
  const wb = getWardrobe();
  wb[dimId] = themeId;
  saveWardrobe(wb);
  applyWardrobe();

  return { success: true, message: `购买成功！「${theme.name}·${dimName}」已装备`, price };
}

// ========== 主题/衣柜应用 ==========

/** 配饰相关的所有CSS变量（应用衣柜前先重置，避免残留） */
const ACCESSORY_VARS = [
  '--calendar-cell-bg', '--calendar-cell-border', '--calendar-radius', '--calendar-dot',
  '--task-bg', '--task-border', '--task-radius', '--task-check',
  '--bg-color', '--bg-gradient', '--bg-pattern', '--bg-pattern-size', '--text-primary', '--text-secondary', '--card-bg', '--card-border',
  '--quote-color', '--quote-shadow',
  '--timer-bg', '--timer-border', '--timer-number', '--timer-shadow',
  '--game-bg', '--game-border', '--game-pattern', '--game-pattern-size',
  '--wardrobe-font-family',
];

/** 应用整主题（设置所有CSS变量） */
function applyTheme(themeId) {
  const theme = getThemeById(themeId);
  currentThemeId = themeId;
  localStorage.setItem(THEME_KEY, themeId);

  const root = document.documentElement;
  ACCESSORY_VARS.forEach(v => root.style.removeProperty(v));
  // 应用所有配饰的CSS变量
  Object.values(theme.accessories).forEach(styles => {
    applyStyles(root, styles);
  });
  const wb = {};
  WARDROBE_DIMENSIONS.forEach(dim => { wb[dim.id] = themeId; });
  updateDimensionClasses(wb);
}

/** 应用衣柜（混搭模式） */
function applyWardrobe() {
  const wb = getWardrobe();
  const root = document.documentElement;

  // 先重置所有配饰变量（回退到:root默认值）
  ACCESSORY_VARS.forEach(v => root.style.removeProperty(v));

  // 按维度顺序应用CSS变量 + 维度主题类名（驱动特色纯CSS配饰）
  WARDROBE_DIMENSIONS.forEach(dim => {
    const themeId = wb[dim.id] || 'wood';
    const theme = getThemeById(themeId);
    if (theme.accessories[dim.id]) {
      applyStyles(root, theme.accessories[dim.id]);
    }
  });
  updateDimensionClasses(wb);
}

/** 在 body 上维护每个维度的主题类名，如 acc-task-bear（供特色CSS配饰使用） */
function updateDimensionClasses(wb) {
  const body = document.body;
  // 移除旧的维度类
  [...body.classList].forEach(cls => {
    if (cls.startsWith('acc-')) body.classList.remove(cls);
  });
  WARDROBE_DIMENSIONS.forEach(dim => {
    body.classList.add(`acc-${dim.id}-${wb[dim.id] || 'wood'}`);
  });
}

/** 将样式对象应用到root（跳过非 CSS 变量字段） */
function applyStyles(root, styles) {
  for (const [key, value] of Object.entries(styles)) {
    if (key === 'fontFamily') {
      root.style.setProperty('--wardrobe-font-family', value);
    } else if (key.startsWith('--')) {
      root.style.setProperty(key, value);
    }
    // decorationImage 等非 CSS 变量字段跳过（由 decoration-manager 处理）
  }
}

/** 获取等级颜色 */
export function getTierColor(tier) {
  return TIERS[tier]?.color || '#888';
}

/** 获取等级CSS类名 */
export function getTierClass(tier) {
  return TIERS[tier]?.cssClass || '';
}

/** 获取等级名称 */
export function getTierName(tier) {
  return TIERS[tier]?.name || tier;
}

/** 获取配饰单价 */
export function getSinglePrice(tier) {
  const prices = { default: 0, normal: 50, advanced: 80, high: 120, top: 170, legend: 250 };
  return prices[tier] || 50;
}

/** 获取当前衣柜中某维度的装饰图片 */
export function getDimensionDecorationImage(dimId) {
  const wb = getWardrobe();
  const themeId = wb[dimId] || 'wood';
  return getDecorationImage(themeId, dimId);
}
