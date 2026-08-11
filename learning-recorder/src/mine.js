/**
 * 我的页面模块 - 金币 + 商城 + 衣柜 + 成就墙 + 统计
 */
import { store } from './store.js';
import {
  getAllThemes, getCurrentThemeId, isThemeOwned,
  getWardrobe, getEquippedTheme, equipAccessory, equipThemeFull,
  purchaseTheme, purchaseAccessory, isAccessoryOwned,
  getOwnedAccessories, getOwnedThemes, getRemainingBundleInfo,
  getDimensions, getTiers, getTierName, getTierClass, getTierColor, getSinglePrice,
} from './theme-manager.js';
import { calcThemeBundlePrice } from './themes.js';
import { playClickSound } from './sound.js';
import { refreshDecorations } from './decoration-manager.js';

let currentTab = 'shop'; // 'shop' | 'wardrobe'

// 成就定义
const ACHIEVEMENTS = [
  { id: 'first_checkin', icon: '🎯', name: '首次打卡', condition: '完成首次学习打卡', check: () => store.getStreakDays() >= 1 },
  { id: 'streak_3', icon: '🔥', name: '连续3天', condition: '连续打卡3天', check: () => store.getStreakDays() >= 3 },
  { id: 'streak_7', icon: '⭐', name: '连续7天', condition: '连续打卡7天', check: () => store.getStreakDays() >= 7 },
  { id: 'study_10h', icon: '📚', name: '学习10小时', condition: '累计学习满10小时', check: () => store.getTotalStudyTime() >= 10 * 3600 },
  { id: 'study_50h', icon: '🏆', name: '学习50小时', condition: '累计学习满50小时', check: () => store.getTotalStudyTime() >= 50 * 3600 },
  { id: 'first_theme', icon: '🎨', name: '首次购买主题', condition: '购买任意一个主题', check: () => getOwnedThemes().some(id => (getAllThemes().find(t => t.id === id)?.tier || 'default') !== 'default') },
];

export function initMine() { renderMinePage(); }

/** 渲染我的页面 */
export function renderMinePage() {
  const page = document.getElementById('page-mine');
  const coins = store.getCoins();
  const streakDays = store.getStreakDays();
  const totalStudySeconds = store.getTotalStudyTime();
  const coinRecords = store.getCoinRecords();

  const totalHours = Math.floor(totalStudySeconds / 3600);
  const totalMins = Math.floor((totalStudySeconds % 3600) / 60);
  const studyTimeStr = totalHours > 0 ? `${totalHours}h${totalMins}m` : `${totalMins}分钟`;
  const recentRecords = coinRecords.slice(-10).reverse();

  page.innerHTML = `
    <h2>👤 我的</h2>

    <!-- 金币卡片 -->
    <div class="mine-coin-card">
      <div class="coin-amount">💰 ${coins}</div>
      <div class="coin-label">金币余额</div>
    </div>

    <!-- 统计 -->
    <div class="mine-stats-grid">
      <div class="stat-card">
        <div class="stat-number">${streakDays}</div>
        <div class="stat-label">连续打卡</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">${studyTimeStr}</div>
        <div class="stat-label">累计学习</div>
      </div>
      <div class="stat-card">
        <div class="stat-number">${coinRecords.length}</div>
        <div class="stat-label">获取次数</div>
      </div>
    </div>

    <!-- 金币记录 -->
    <div class="card">
      <h3>📊 金币记录</h3>
      ${recentRecords.length === 0
        ? '<div class="empty-hint">还没有金币记录，开始学习赚取金币吧！</div>'
        : `<div class="coin-record-list">
            ${recentRecords.map(r => `
              <div class="coin-record-item">
                <div class="record-info">
                  <span class="record-reason">${r.reason}</span>
                  <span class="record-date">${formatDate(r.date)}</span>
                </div>
                <span class="record-amount ${r.amount < 0 ? 'negative' : ''}">${r.amount > 0 ? '+' : ''}${r.amount}</span>
              </div>
            `).join('')}
          </div>`
      }
    </div>

    <!-- Tab切换: 商城 / 衣柜 -->
    <div class="shop-wardrobe-tabs">
      <button class="sw-tab ${currentTab === 'shop' ? 'active' : ''}" data-tab="shop">🎨 商城</button>
      <button class="sw-tab ${currentTab === 'wardrobe' ? 'active' : ''}" data-tab="wardrobe">👔 衣柜</button>
    </div>

    <!-- 商城内容 -->
    <div class="sw-content ${currentTab === 'shop' ? 'active' : ''}" id="shop-content">
      ${renderShop()}
    </div>

    <!-- 衣柜内容 -->
    <div class="sw-content ${currentTab === 'wardrobe' ? 'active' : ''}" id="wardrobe-content">
      ${renderWardrobe()}
    </div>

    <!-- 成就墙 -->
    <div class="card achievement-section">
      <h3>🏆 成就墙</h3>
      ${renderAchievements()}
    </div>

    <!-- 统计图表 -->
    <div class="card stats-section">
      <h3>📈 本周学习</h3>
      ${renderWeeklyChart()}
      ${renderStatsSummary()}
    </div>
  `;

  bindEvents();
}

/** 渲染商城 */
function renderShop() {
  const themes = getAllThemes();
  const coins = store.getCoins();
  const dims = getDimensions();

  return `
    <div class="card">
      <div class="shop-header">
        <h3>🎨 主题商城</h3>
        <span class="shop-hint"> ${coins} 金币</span>
      </div>
      <div class="theme-grid">
        ${themes.map(theme => {
          const owned = isThemeOwned(theme.id);
          const tierClass = getTierClass(theme.tier);
          const tierName = getTierName(theme.tier);
          const bundleInfo = getRemainingBundleInfo(theme.id);
          const bundlePrice = bundleInfo.price;
          const dimCount = bundleInfo.total;
          const singlePrice = getSinglePrice(theme.tier);

          // 预览色块：取bg配饰中的bg-color
          const previewColor = theme.accessories.bg?.['--bg-color'] || '#ccc';
          const previewAccent = theme.accessories.calendar?.['--calendar-cell-border'] || theme.accessories.task?.['--task-border'] || '#999';
          // 按钮主题色：每个主题独立定义，互不相同
          const btnColor = theme.btnColor || '#888888';

          if (!theme.available) {
            // 即将上线
            return `
              <div class="theme-card coming-soon">
                <div class="theme-preview-swatch" style="background:${previewColor};border-color:${previewAccent}"></div>
                <div class="theme-emoji">${theme.emoji}</div>
                <div class="theme-name">${theme.name}</div>
                <span class="theme-tier ${tierClass}">${tierName}</span>
                <div class="theme-price" style="color:#999">${dimCount}配饰 · ${singlePrice}/个</div>
                <button class="theme-btn theme-btn-locked" disabled>即将上线</button>
              </div>
            `;
          }

          if (owned) {
            return `
              <div class="theme-card owned">
                <div class="theme-preview-swatch" style="background:${previewColor};border-color:${previewAccent}"></div>
                <div class="theme-emoji">${theme.emoji}</div>
                <div class="theme-name">${theme.name}</div>
                <span class="theme-tier ${tierClass}">${tierName}</span>
                <div class="theme-price owned">已拥有 · ${dimCount}配饰</div>
                <button class="theme-btn theme-btn-equip" style="background:${btnColor};color:#fff"
                  data-action="equip-full" data-theme-id="${theme.id}">🎽 整套装备</button>
              </div>
            `;
          }

          const canAfford = coins >= bundlePrice;
          return `
            <div class="theme-card">
              <div class="theme-preview-swatch" style="background:${previewColor};border-color:${previewAccent}"></div>
              <div class="theme-emoji">${theme.emoji}</div>
              <div class="theme-name">${theme.name}</div>
              <span class="theme-tier ${tierClass}">${tierName}</span>
              <div class="theme-price">💰 ${bundlePrice} ${bundleInfo.ownedCount > 0 ? `<span style="font-size:11px;color:#4CAF50">已拥有${bundleInfo.ownedCount}件，已扣除</span>` : `<span style="font-size:11px;color:#999;text-decoration:line-through">${dimCount * singlePrice}</span>`}</div>
              <button class="theme-btn ${canAfford ? 'theme-btn-buy' : 'theme-btn-locked'}" 
                style="${canAfford ? `background:${btnColor};color:#fff` : ''}"
                data-action="buy-theme" data-theme-id="${theme.id}" ${canAfford ? '' : 'disabled'}>
                ${canAfford ? `购买整主题` : '金币不足'}
              </button>
              <div class="single-buy-row">
                ${dims.map(dim => {
                  const accOwned = isAccessoryOwned(theme.id, dim.id);
                  const price = singlePrice;
                  const canBuy = coins >= price && !accOwned;
                  return `
                    <button class="single-buy-btn ${accOwned ? 'owned' : ''}" 
                      style="${accOwned ? `border-color:${btnColor};color:${btnColor}` : ''}"
                      data-action="buy-accessory" data-theme-id="${theme.id}" data-dim-id="${dim.id}" 
                      ${canBuy ? '' : 'disabled'} title="${dim.name} ${price}金币">
                      ${dim.icon}${accOwned ? '✓' : price}
                    </button>
                  `;
                }).join('')}
              </div>
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

/** 渲染衣柜 */
function renderWardrobe() {
  const dims = getDimensions();
  const wardrobe = getWardrobe();
  const ownedAcc = getOwnedAccessories();
  const themes = getAllThemes();

  return `
    <div class="card">
      <div class="wardrobe-header">
        <h3>👔 我的衣柜</h3>
        <span class="wardrobe-hint">已拥有 ${ownedAcc.length} 件配饰</span>
      </div>
      <div class="wardrobe-list">
        ${dims.map(dim => {
          const equippedThemeId = wardrobe[dim.id] || 'wood';
          const equippedTheme = themes.find(t => t.id === equippedThemeId);
          const ownedForDim = ownedAcc.filter(a => a.dimId === dim.id);

          return `
            <div class="wardrobe-dimension">
              <div class="wardrobe-dim-header">
                <span class="wardrobe-dim-icon">${dim.icon}</span>
                <span class="wardrobe-dim-name">${dim.name}</span>
                <span class="wardrobe-dim-equipped">${equippedTheme?.emoji || ''} ${equippedTheme?.name || '未装备'}</span>
              </div>
              <div class="wardrobe-dim-options">
                ${ownedForDim.length === 0
                  ? '<div class="empty-hint" style="padding:8px">暂无该维度配饰</div>'
                  : ownedForDim.map(acc => {
                      const accTheme = themes.find(t => t.id === acc.themeId);
                      const isEquipped = acc.themeId === equippedThemeId;
                      return `
                        <button class="wardrobe-option ${isEquipped ? 'equipped' : ''}" 
                          data-action="equip" data-dim="${dim.id}" data-theme="${acc.themeId}">
                          <span>${accTheme?.emoji || ''} ${accTheme?.name || ''}</span>
                          ${isEquipped ? '<span class="equipped-badge">✓</span>' : ''}
                        </button>
                      `;
                    }).join('')
                }
              </div>
            </div>
          `;
        }).join('')}
      </div>
    </div>
  `;
}

/** 渲染成就墙 */
function renderAchievements() {
  return `
    <div class="achievement-grid">
      ${ACHIEVEMENTS.map(ach => {
        const unlocked = ach.check();
        return `
          <div class="achievement-card ${unlocked ? 'unlocked' : 'locked'}">
            <div class="achievement-icon">${ach.icon}</div>
            <div class="achievement-name">${ach.name}</div>
            <div class="achievement-condition">${ach.condition}</div>
            ${unlocked ? '<div class="achievement-badge">已解锁</div>' : ''}
          </div>
        `;
      }).join('')}
    </div>
  `;
}

/** 渲染本周学习柱状图 */
function renderWeeklyChart() {
  const weekData = store.getRecentStudyDays(7);
  const today = store.getToday();
  const maxSeconds = Math.max(...weekData.map(d => d.seconds), 1);

  return `
    <div class="weekly-chart">
      ${weekData.map(d => {
        const height = Math.max(4, (d.seconds / maxSeconds) * 80);
        const mins = Math.floor(d.seconds / 60);
        const isToday = d.date === today;
        const label = mins >= 60 ? `${Math.floor(mins/60)}h` : `${mins}m`;
        return `
          <div class="chart-bar-wrapper">
            <div class="chart-bar-value">${label || '-'}</div>
            <div class="chart-bar ${isToday ? 'today' : ''}" style="height:${height}px"></div>
            <div class="chart-bar-label">${d.label}</div>
          </div>
        `;
      }).join('')}
    </div>
  `;
}

/** 渲染统计摘要 */
function renderStatsSummary() {
  const totalStudySeconds = store.getTotalStudyTime();
  const totalHours = Math.floor(totalStudySeconds / 3600);
  const totalMins = Math.floor((totalStudySeconds % 3600) / 60);
  const studyTimeStr = totalHours > 0 ? `${totalHours}h${totalMins}m` : `${totalMins}分钟`;
  const totalTasks = store.getTotalCompletedTasks();
  const totalCoins = store.getCoinRecords().reduce((sum, r) => sum + Math.max(0, r.amount), 0);

  return `
    <div class="stats-summary">
      <div class="stats-summary-item">
        <div class="stats-summary-value">${studyTimeStr}</div>
        <div class="stats-summary-label">总学习时长</div>
      </div>
      <div class="stats-summary-item">
        <div class="stats-summary-value">${totalTasks}</div>
        <div class="stats-summary-label">完成任务数</div>
      </div>
      <div class="stats-summary-item">
        <div class="stats-summary-value">${totalCoins}</div>
        <div class="stats-summary-label">总获取金币</div>
      </div>
    </div>
  `;
}

/** 绑定事件 */
function bindEvents() {
  // Tab切换
  document.querySelectorAll('.sw-tab').forEach(tab => {
    tab.addEventListener('click', () => {
      playClickSound();
      currentTab = tab.dataset.tab;
      document.querySelectorAll('.sw-tab').forEach(t => t.classList.remove('active'));
      document.querySelectorAll('.sw-content').forEach(c => c.classList.remove('active'));
      tab.classList.add('active');
      document.getElementById(`${currentTab}-content`).classList.add('active');
    });
  });

  // 购买整主题
  document.querySelectorAll('[data-action="buy-theme"]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (btn.disabled) return;
      playClickSound();
      const themeId = btn.dataset.themeId;
      showConfirmDialog(themeId, 'theme');
    });
  });

  // 购买单个配饰
  document.querySelectorAll('[data-action="buy-accessory"]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (btn.disabled) return;
      playClickSound();
      const themeId = btn.dataset.themeId;
      const dimId = btn.dataset.dimId;
      showConfirmDialog(themeId, 'accessory', dimId);
    });
  });

  // 整套装备（已拥有主题）
  document.querySelectorAll('[data-action="equip-full"]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      playClickSound();
      const result = equipThemeFull(btn.dataset.themeId);
      showToast(result.message);
      if (result.success) {
        refreshDecorations();
        renderMinePage();
      }
    });
  });

  // 装备配饰
  document.querySelectorAll('[data-action="equip"]').forEach(btn => {
    btn.addEventListener('click', (e) => {
      e.stopPropagation();
      playClickSound();
      const dimId = btn.dataset.dim;
      const themeId = btn.dataset.theme;
      const result = equipAccessory(dimId, themeId);
      if (result.success) {
        showToast(result.message);
        refreshDecorations();
        renderMinePage();
      }
    });
  });
}

/** 显示购买确认弹窗 */
function showConfirmDialog(themeId, type, dimId) {
  const themes = getAllThemes();
  const theme = themes.find(t => t.id === themeId);
  if (!theme) return;

  const singlePrice = getSinglePrice(theme.tier);
  const dims = getDimensions();

  const overlay = document.createElement('div');
  overlay.className = 'confirm-overlay';

  if (type === 'theme') {
    // 整主题购买（已单买配饰自动扣除）
    const info = getRemainingBundleInfo(themeId);
    const bundlePrice = info.price;
    const dimCount = info.total;

    overlay.innerHTML = `
      <div class="confirm-dialog">
        <div class="confirm-emoji">${theme.emoji}</div>
        <h3>${theme.name}</h3>
        <span class="theme-tier ${getTierClass(theme.tier)}">${getTierName(theme.tier)}</span>
        <div class="confirm-details">
          <div class="confirm-row">
            <span>配饰数量</span>
            <span>${dimCount} 个维度${info.ownedCount > 0 ? `（已拥有 ${info.ownedCount} 件）` : ''}</span>
          </div>
          <div class="confirm-row">
            <span>整主题原价</span>
            <span style="text-decoration:line-through;color:#999">${info.fullPrice} 金币</span>
          </div>
          ${info.ownedCount > 0 ? `
          <div class="confirm-row">
            <span>已购配饰抵扣</span>
            <span style="color:#4CAF50;font-weight:600">-${info.ownedCount * info.singlePrice} 金币</span>
          </div>` : ''}
          <div class="confirm-row highlight">
            <span>实际应付</span>
            <span style="color:var(--accent);font-weight:700">💰 ${bundlePrice} 金币</span>
          </div>
          <div class="confirm-row">
            <span>当前余额</span>
            <span>💰 ${store.getCoins()} 金币</span>
          </div>
        </div>
        <p class="confirm-warning">购买后配饰将自动装备到衣柜，也可在衣柜中自由混搭</p>
        <div class="confirm-actions">
          <button class="btn-secondary" id="confirm-cancel">再想想</button>
          <button class="btn-primary" id="confirm-buy" ${store.getCoins() < bundlePrice ? 'disabled' : ''}>
            ${store.getCoins() < bundlePrice ? '金币不足' : '确认购买'}
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    document.getElementById('confirm-cancel').addEventListener('click', () => overlay.remove());

    const buyBtn = document.getElementById('confirm-buy');
    if (!buyBtn.disabled) {
      buyBtn.addEventListener('click', () => {
        const result = purchaseTheme(themeId);
        overlay.remove();
        if (result.success) {
          showToast(result.message);
          refreshDecorations();
          renderMinePage();
        } else {
          showToast(result.message);
        }
      });
    }
  } else if (type === 'accessory' && dimId) {
    // 单个配饰购买
    const dim = dims.find(d => d.id === dimId);
    const accOwned = isAccessoryOwned(themeId, dimId);

    overlay.innerHTML = `
      <div class="confirm-dialog">
        <div class="confirm-emoji">${theme.emoji}</div>
        <h3>${theme.name} - ${dim?.name || ''}</h3>
        <span class="theme-tier ${getTierClass(theme.tier)}">${getTierName(theme.tier)}</span>
        <div class="confirm-details">
          <div class="confirm-row">
            <span>配饰维度</span>
            <span>${dim?.icon || ''} ${dim?.name || ''}</span>
          </div>
          <div class="confirm-row highlight">
            <span>价格</span>
            <span style="color:var(--accent);font-weight:700">💰 ${singlePrice} 金币</span>
          </div>
          <div class="confirm-row">
            <span>当前余额</span>
            <span>💰 ${store.getCoins()} 金币</span>
          </div>
        </div>
        <p class="confirm-warning">购买后可在衣柜中装备此配饰</p>
        <div class="confirm-actions">
          <button class="btn-secondary" id="confirm-cancel">再想想</button>
          <button class="btn-primary" id="confirm-buy" ${store.getCoins() < singlePrice || accOwned ? 'disabled' : ''}>
            ${accOwned ? '已拥有' : store.getCoins() < singlePrice ? '金币不足' : '确认购买'}
          </button>
        </div>
      </div>
    `;

    document.body.appendChild(overlay);

    document.getElementById('confirm-cancel').addEventListener('click', () => overlay.remove());

    const buyBtn = document.getElementById('confirm-buy');
    if (!buyBtn.disabled) {
      buyBtn.addEventListener('click', () => {
        const result = purchaseAccessory(themeId, dimId);
        overlay.remove();
        if (result.success) {
          showToast(result.message);
          refreshDecorations();
          renderMinePage();
        } else {
          showToast(result.message);
        }
      });
    }
  }

  overlay.addEventListener('click', (e) => {
    if (e.target === overlay) overlay.remove();
  });
}

/** 显示提示 */
function showToast(message) {
  const toast = document.createElement('div');
  toast.className = 'toast-msg';
  toast.textContent = message;
  document.body.appendChild(toast);
  setTimeout(() => {
    toast.classList.add('fade-out');
    setTimeout(() => toast.remove(), 300);
  }, 2000);
}

function formatDate(dateStr) {
  if (dateStr === store.getToday()) return '今天';
  const date = new Date(dateStr + 'T00:00:00');
  return `${date.getMonth() + 1}月${date.getDate()}日`;
}
