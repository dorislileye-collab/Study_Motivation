/**
 * 主入口 - Tab切换 + 模块初始化
 */
import { initTheme } from './src/theme-manager.js';
import { refreshDecorations } from './src/decoration-manager.js';
import { initHome, renderHome } from './src/home.js';
import { initCalendar, renderCalendar } from './src/calendar.js';
import { initTimer, renderTimerPage } from './src/timer.js';
import { initGame, renderGamePage, cleanupGame } from './src/game.js';
import { initMine, renderMinePage } from './src/mine.js';

// ========== 初始化主题（最先执行，设置CSS变量） ==========
initTheme();

// ========== Tab 切换逻辑 ==========
const tabItems = document.querySelectorAll('.tab-item');
const pages = document.querySelectorAll('.page');

tabItems.forEach(tab => {
  tab.addEventListener('click', () => {
    const targetPage = tab.dataset.page;

    tabItems.forEach(t => t.classList.remove('active'));
    pages.forEach(p => p.classList.remove('active'));

    tab.classList.add('active');
    document.getElementById(targetPage).classList.add('active');

    // 切换到对应页面时刷新内容
    if (targetPage === 'page-home') renderHome();
    if (targetPage === 'page-calendar') renderCalendar();
    if (targetPage === 'page-timer') renderTimerPage();
    if (targetPage === 'page-game') renderGamePage();
    if (targetPage === 'page-mine') renderMinePage();

    // 刷新装饰
    refreshDecorations();

    // 离开游戏页时清理计时器
    if (targetPage !== 'page-game') cleanupGame();
  });
});

// ========== 初始化各模块 ==========
initHome();
initCalendar();
initTimer();
initGame();
initMine();
refreshDecorations();

console.log('✅ 学习激励记录仪 已加载');
