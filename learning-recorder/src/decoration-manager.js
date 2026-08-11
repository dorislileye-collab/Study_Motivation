/**
 * 装饰管理器 - 根据衣柜装备状态在页面中智能放置装饰图片
 * 支持：常规定位、浮动动画、视差效果、交互响应、主题氛围渲染
 */
import { getWardrobe } from './theme-manager.js';

/**
 * 装饰规则配置
 * 每条规则定义：图片路径、显示位置、触发主题、触发维度、动画类型
 *
 * position 类型：
 * - 常规定位: calendar-top-right, calendar-bottom-right, game-bottom-right 等
 * - 特殊动画: bg-floating, bg-bottom, game-top-petals, game-sides, calendar-bat-fly
 * - 首页装饰: home-corner-tl, home-corner-br, home-floating
 * - 计时器装饰: timer-corner, timer-floating
 * - 我的页装饰: mine-header, mine-floating
 * - 情绪粉碎机: crush-floating
 */
const DECORATION_RULES = [
  // ===== 日历页装饰 =====
  { image: 'public/sketches/bear-head.jpeg', position: 'calendar-top-right', theme: 'bear', dimension: 'calendar', container: 'page-calendar' },
  { image: 'public/sketches/cat-head.jpeg', position: 'calendar-top-right', theme: 'cat', dimension: 'calendar', container: 'page-calendar' },
  { image: 'public/sketches/seashell.jpeg', position: 'calendar-bottom-right', theme: 'beach', dimension: 'calendar', container: 'page-calendar' },
  { image: null, position: 'calendar-bat-fly', theme: 'gothic', dimension: 'calendar', container: 'page-calendar' },
  // 日历页额外装饰 - 左下角
  { image: 'public/sketches/potted-plant.jpeg', position: 'calendar-bottom-left', theme: 'springgreen', dimension: 'calendar', container: 'page-calendar' },
  { image: 'public/sketches/crab.jpeg', position: 'calendar-bottom-left', theme: 'beach', dimension: 'calendar', container: 'page-calendar' },

  // ===== 首页装饰 =====
  { image: 'public/sketches/fish-snack.jpeg', position: 'quote-right', theme: 'cat', dimension: 'quote', container: 'page-home' },
  { image: 'public/sketches/bear-paw.jpeg', position: 'task-checkbox', theme: 'bear', dimension: 'task', container: 'page-home' },
  { image: 'public/sketches/cat-paw.jpeg', position: 'task-checkbox', theme: 'cat', dimension: 'task', container: 'page-home' },
  // 首页角落装饰
  { image: 'public/sketches/cherry-blossom.jpeg', position: 'home-corner-tl', theme: 'sakura', dimension: 'bg', container: 'page-home' },
  { image: 'public/sketches/butterfly.jpeg', position: 'home-floating', theme: 'springgreen', dimension: 'bg', container: 'page-home' },
  { image: 'public/sketches/palm-leaf.jpeg', position: 'home-corner-tr', theme: 'beach', dimension: 'bg', container: 'page-home' },
  { image: 'public/sketches/bear-cheer.jpeg', position: 'home-corner-br', theme: 'bear', dimension: 'bg', container: 'page-home' },

  // ===== 背景层装饰 =====
  { image: 'public/sketches/jellyfish.jpeg', position: 'bg-floating', theme: 'deepsea', dimension: 'bg', container: 'body' },
  { image: 'public/sketches/city-skyline.jpeg', position: 'bg-bottom', theme: 'cyber', dimension: 'bg', container: 'body' },
  // 额外背景装饰
  { image: 'public/sketches/butterfly.jpeg', position: 'bg-floating-light', theme: 'springgreen', dimension: 'bg', container: 'body' },
  { image: 'public/sketches/cherry-blossom.jpeg', position: 'bg-petal-fall', theme: 'sakura', dimension: 'bg', container: 'body' },

  // ===== 游戏页装饰 =====
  { image: 'public/sketches/crab.jpeg', position: 'game-bottom-right', theme: 'beach', dimension: 'game', container: 'page-game' },
  { image: 'public/sketches/palm-leaf.jpeg', position: 'game-sides', theme: 'beach', dimension: 'game', container: 'page-game' },
  { image: 'public/sketches/cherry-blossom.jpeg', position: 'game-top-petals', theme: 'sakura', dimension: 'game', container: 'page-game' },
  { image: 'public/sketches/butterfly.jpeg', position: 'game-top-right-fly', theme: 'springgreen', dimension: 'game', container: 'page-game' },
  { image: 'public/sketches/potted-plant.jpeg', position: 'game-bottom-left', theme: 'wood', dimension: 'game', container: 'page-game' },
  // 游戏页额外装饰
  { image: 'public/sketches/cat-head.jpeg', position: 'game-watching', theme: 'cat', dimension: 'game', container: 'page-game' },
  { image: 'public/sketches/bear-head.jpeg', position: 'game-watching', theme: 'bear', dimension: 'game', container: 'page-game' },

  // ===== 计时器页装饰 =====
  { image: 'public/sketches/bear-cheer.jpeg', position: 'timer-celebration', theme: 'bear', dimension: 'timer', container: 'special' },
  { image: 'public/sketches/cat-paw.jpeg', position: 'timer-corner-deco', theme: 'cat', dimension: 'timer', container: 'page-timer' },
  { image: 'public/sketches/bear-paw.jpeg', position: 'timer-corner-deco', theme: 'bear', dimension: 'timer', container: 'page-timer' },
  { image: 'public/sketches/fish-snack.jpeg', position: 'timer-floating', theme: 'cat', dimension: 'timer', container: 'page-timer' },
  { image: 'public/sketches/seashell.jpeg', position: 'timer-bottom-deco', theme: 'beach', dimension: 'timer', container: 'page-timer' },
  { image: 'public/sketches/potted-plant.jpeg', position: 'timer-bottom-deco', theme: 'wood', dimension: 'timer', container: 'page-timer' },

  // ===== 我的页面装饰 =====
  { image: 'public/sketches/bear-head.jpeg', position: 'mine-header-deco', theme: 'bear', dimension: 'bg', container: 'page-mine' },
  { image: 'public/sketches/cat-head.jpeg', position: 'mine-header-deco', theme: 'cat', dimension: 'bg', container: 'page-mine' },
  { image: 'public/sketches/crab.jpeg', position: 'mine-corner-deco', theme: 'beach', dimension: 'bg', container: 'page-mine' },
  { image: 'public/sketches/butterfly.jpeg', position: 'mine-floating-deco', theme: 'springgreen', dimension: 'bg', container: 'page-mine' },
  { image: 'public/sketches/cherry-blossom.jpeg', position: 'mine-corner-tl', theme: 'sakura', dimension: 'bg', container: 'page-mine' },

  // ===== 情绪粉碎机页装饰 =====
  { image: 'public/sketches/butterfly.jpeg', position: 'crush-floating', theme: 'springgreen', dimension: 'game', container: 'page-game' },
  { image: 'public/sketches/jellyfish.jpeg', position: 'crush-floating', theme: 'deepsea', dimension: 'game', container: 'page-game' },
];

let activeDecorations = [];
let bgAnimationId = null;
let scrollHandlers = [];

/**
 * 刷新所有装饰（衣柜变化或页面切换时调用）
 */
export function refreshDecorations() {
  clearAllDecorations();
  const wardrobe = getWardrobe();

  DECORATION_RULES.forEach(rule => {
    // 检查该维度是否装备了对应主题
    const equippedTheme = wardrobe[rule.dimension];
    if (equippedTheme !== rule.theme) return;

    // 特殊位置处理
    if (rule.position === 'task-checkbox') {
      applyTaskCheckboxDecoration(rule.image, rule.theme);
      return;
    }
    if (rule.position === 'timer-celebration') {
      // 计时庆祝图由 timer.js 手动触发
      return;
    }
    if (rule.position === 'quote-right') {
      // 激励横幅内的装饰图由 home.js 通过 getQuoteDecorationImage() 插入
      return;
    }
    if (rule.position === 'bg-floating') {
      createFloatingBackground(rule.image, 4);
      return;
    }
    if (rule.position === 'bg-floating-light') {
      createFloatingLight(rule.image, 5);
      return;
    }
    if (rule.position === 'bg-petal-fall') {
      createPetalFall(rule.image);
      return;
    }
    if (rule.position === 'bg-bottom') {
      createBackgroundBottom(rule.image);
      return;
    }
    if (rule.position === 'game-top-petals') {
      createPetalAnimation(rule.image);
      return;
    }
    if (rule.position === 'game-sides') {
      createGameSidesDecoration(rule.image);
      return;
    }
    if (rule.position === 'calendar-bat-fly') {
      createFlyingBats(rule.container);
      return;
    }
    if (rule.position === 'home-floating' || rule.position === 'mine-floating-deco') {
      createButterflyFloat(rule.image, rule.container);
      return;
    }
    if (rule.position === 'game-watching') {
      createWatchingDecoration(rule.image, rule.container);
      return;
    }
    if (rule.position === 'timer-floating') {
      createTimerFloating(rule.image, rule.container);
      return;
    }
    if (rule.position === 'crush-floating') {
      createCrushFloating(rule.image, rule.container);
      return;
    }

    // 常规定位装饰
    const container = document.getElementById(rule.container);
    if (!container) return;

    const img = document.createElement('img');
    img.src = rule.image;
    img.alt = '';
    img.className = rule.position.startsWith('game-')
      ? `deco-${rule.position}`
      : `decoration-img ${rule.position}`;
    img.style.mixBlendMode = 'multiply';

    // 为不同位置添加特定样式
    applyPositionStyle(img, rule.position);

    container.style.position = 'relative';
    container.appendChild(img);
    activeDecorations.push(img);
  });

  // 添加视差滚动效果
  addParallaxEffect();
}

/**
 * 根据位置应用特定样式
 */
function applyPositionStyle(img, position) {
  const baseStyle = {
    transition: 'transform 0.3s ease-out',
  };

  switch (position) {
    case 'calendar-bottom-left':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        bottom: '10px',
        left: '10px',
        width: '50px',
        height: '50px',
        objectFit: 'contain',
        opacity: '0.7',
      });
      break;
    case 'home-corner-tl':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        top: '-5px',
        left: '-5px',
        width: '80px',
        height: '80px',
        objectFit: 'contain',
        opacity: '0.6',
        zIndex: '0',
        pointerEvents: 'none',
      });
      break;
    case 'home-corner-tr':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        top: '-5px',
        right: '-10px',
        width: '70px',
        height: '90px',
        objectFit: 'contain',
        opacity: '0.5',
        zIndex: '0',
        pointerEvents: 'none',
      });
      break;
    case 'home-corner-br':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        bottom: '60px',
        right: '5px',
        width: '55px',
        height: '55px',
        objectFit: 'contain',
        opacity: '0.5',
        zIndex: '0',
        pointerEvents: 'none',
        animation: 'deco-gentle-bounce 4s ease-in-out infinite',
      });
      break;
    case 'timer-corner-deco':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        top: '70px',
        right: '8px',
        width: '45px',
        height: '45px',
        objectFit: 'contain',
        opacity: '0.5',
        pointerEvents: 'none',
        animation: 'deco-sway 5s ease-in-out infinite',
      });
      break;
    case 'timer-bottom-deco':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        bottom: '80px',
        left: '50%',
        transform: 'translateX(-50%)',
        width: '60px',
        height: '60px',
        objectFit: 'contain',
        opacity: '0.4',
        pointerEvents: 'none',
      });
      break;
    case 'mine-header-deco':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        top: '5px',
        right: '10px',
        width: '50px',
        height: '50px',
        objectFit: 'contain',
        opacity: '0.6',
        pointerEvents: 'none',
        animation: 'deco-peek 6s ease-in-out infinite',
      });
      break;
    case 'mine-corner-deco':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        bottom: '70px',
        right: '8px',
        width: '45px',
        height: '45px',
        objectFit: 'contain',
        opacity: '0.5',
        pointerEvents: 'none',
        animation: 'deco-sway 4s ease-in-out infinite',
      });
      break;
    case 'mine-corner-tl':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        top: '0',
        left: '0',
        width: '70px',
        height: '70px',
        objectFit: 'contain',
        opacity: '0.4',
        pointerEvents: 'none',
      });
      break;
    case 'game-top-right-fly':
      Object.assign(img.style, baseStyle, {
        position: 'absolute',
        top: '60px',
        right: '15px',
        width: '35px',
        height: '35px',
        objectFit: 'contain',
        opacity: '0.7',
        pointerEvents: 'none',
        animation: 'deco-fly-around 8s ease-in-out infinite',
      });
      break;
  }
}

/**
 * 蝴蝶漂浮效果
 */
function createButterflyFloat(image, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.style.position = 'relative';

  for (let i = 0; i < 3; i++) {
    const img = document.createElement('img');
    img.src = image;
    img.alt = '';
    img.className = 'deco-butterfly-float';
    img.style.mixBlendMode = 'multiply';
    img.style.left = `${15 + Math.random() * 70}%`;
    img.style.top = `${20 + Math.random() * 50}%`;
    img.style.animationDelay = `${i * 2.5}s`;
    img.style.animationDuration = `${6 + Math.random() * 4}s`;
    img.style.width = `${25 + Math.random() * 15}px`;
    container.appendChild(img);
    activeDecorations.push(img);
  }
}

/**
 * 偷看装饰（游戏页角落的小动物）
 */
function createWatchingDecoration(image, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.style.position = 'relative';

  const img = document.createElement('img');
  img.src = image;
  img.alt = '';
  img.className = 'deco-watching';
  img.style.mixBlendMode = 'multiply';
  container.appendChild(img);
  activeDecorations.push(img);
}

/**
 * 计时器页漂浮装饰
 */
function createTimerFloating(image, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.style.position = 'relative';

  const img = document.createElement('img');
  img.src = image;
  img.alt = '';
  img.style.position = 'absolute';
  img.style.bottom = '100px';
  img.style.left = '10px';
  img.style.width = '35px';
  img.style.height = '35px';
  img.style.objectFit = 'contain';
  img.style.opacity = '0.5';
  img.style.pointerEvents = 'none';
  img.style.animation = 'deco-gentle-bounce 5s ease-in-out infinite';
  img.style.mixBlendMode = 'multiply';
  container.appendChild(img);
  activeDecorations.push(img);
}

/**
 * 轻盈漂浮背景（如蝴蝶在springgreen主题）
 */
function createFloatingLight(image, count) {
  for (let i = 0; i < count; i++) {
    const img = document.createElement('img');
    img.src = image;
    img.alt = '';
    img.className = 'deco-bg-float-light';
    img.style.left = `${Math.random() * 90}%`;
    img.style.animationDelay = `${Math.random() * 10}s`;
    img.style.animationDuration = `${10 + Math.random() * 8}s`;
    img.style.width = `${20 + Math.random() * 20}px`;
    document.body.appendChild(img);
    activeDecorations.push(img);
  }
}

/**
 * 花瓣飘落背景效果
 */
function createPetalFall(image) {
  for (let i = 0; i < 8; i++) {
    const img = document.createElement('img');
    img.src = image;
    img.alt = '';
    img.className = 'deco-petal-fall';
    img.style.left = `${Math.random() * 100}%`;
    img.style.animationDelay = `${Math.random() * 10}s`;
    img.style.animationDuration = `${8 + Math.random() * 6}s`;
    img.style.width = `${12 + Math.random() * 12}px`;
    document.body.appendChild(img);
    activeDecorations.push(img);
  }
}

/**
 * 情绪粉碎机页漂浮装饰
 */
function createCrushFloating(image, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.style.position = 'relative';

  for (let i = 0; i < 2; i++) {
    const img = document.createElement('img');
    img.src = image;
    img.alt = '';
    img.style.position = 'absolute';
    img.style.width = `${25 + Math.random() * 15}px`;
    img.style.height = img.style.width;
    img.style.objectFit = 'contain';
    img.style.opacity = '0.3';
    img.style.pointerEvents = 'none';
    img.style.mixBlendMode = 'multiply';
    img.style.left = `${10 + Math.random() * 80}%`;
    img.style.top = `${30 + Math.random() * 40}%`;
    img.style.animation = `deco-gentle-bounce ${5 + Math.random() * 3}s ease-in-out infinite`;
    img.style.animationDelay = `${i * 2}s`;
    container.appendChild(img);
    activeDecorations.push(img);
  }
}

/**
 * 清除所有装饰元素
 */
function clearAllDecorations() {
  activeDecorations.forEach(el => el.remove());
  activeDecorations = [];
  if (bgAnimationId) {
    cancelAnimationFrame(bgAnimationId);
    bgAnimationId = null;
  }
  // 清除滚动监听
  scrollHandlers.forEach(({ el, handler }) => {
    el.removeEventListener('scroll', handler, { passive: true });
  });
  scrollHandlers = [];
}

/**
 * 添加视差滚动效果
 */
function addParallaxEffect() {
  const pageContainer = document.getElementById('page-container');
  if (!pageContainer) return;

  const handler = () => {
    const scrollY = pageContainer.scrollTop;
    activeDecorations.forEach((el, i) => {
      if (el.classList.contains('deco-bg-float') || el.classList.contains('deco-bg-float-light')) {
        const speed = 0.02 + (i % 3) * 0.01;
        el.style.transform = `translateY(${scrollY * speed}px)`;
      }
    });
  };

  pageContainer.addEventListener('scroll', handler, { passive: true });
  scrollHandlers.push({ el: pageContainer, handler });
}

/**
 * 任务勾选框装饰（替换默认勾选框图标）
 */
function applyTaskCheckboxDecoration(image, themeId) {
  const taskCheckboxes = document.querySelectorAll('.task-checkbox');
  taskCheckboxes.forEach(box => {
    const taskItem = box.closest('.task-item');
    const isCompleted = taskItem?.classList.contains('completed');

    // 创建爪印图片（内联限尺寸，避免大图撑破布局）
    const img = document.createElement('img');
    img.src = image;
    img.alt = '';
    img.className = 'task-checkbox-deco';
    img.width = 15;
    img.height = 15;
    img.style.maxWidth = '15px';
    img.style.maxHeight = '15px';
    img.style.mixBlendMode = 'multiply';
    img.style.opacity = isCompleted ? '1' : '0.4';
    img.style.filter = isCompleted ? 'none' : 'grayscale(0.5)';

    // 替换原有勾选框内容
    box.innerHTML = '';
    box.appendChild(img);
    activeDecorations.push(img);
  });
}

/**
 * 背景漂浮装饰（如水母：深色背景下反色+screen混合，呈现发光效果）
 */
function createFloatingBackground(image, count) {
  for (let i = 0; i < count; i++) {
    const img = document.createElement('img');
    img.src = image;
    img.alt = '';
    img.className = 'deco-bg-float';
    // 白底草图反色后用 screen 混合：白底变透明，线条变亮发光，深海可见
    img.style.filter = 'invert(1)';
    img.style.mixBlendMode = 'screen';
    img.style.left = `${10 + Math.random() * 80}%`;
    img.style.animationDelay = `${Math.random() * 8}s`;
    img.style.animationDuration = `${12 + Math.random() * 8}s`;
    img.style.width = `${30 + Math.random() * 30}px`;
    document.body.appendChild(img);
    activeDecorations.push(img);
  }
}

/**
 * 背景底部装饰（如城市天际线）
 */
function createBackgroundBottom(image) {
  const img = document.createElement('img');
  img.src = image;
  img.alt = '';
  img.className = 'deco-bg-bottom';
  img.style.mixBlendMode = 'multiply';
  document.body.appendChild(img);
  activeDecorations.push(img);
}

/**
 * 游戏页顶部樱花枝装饰 + CSS花瓣飘落动画
 */
function createPetalAnimation(image) {
  const container = document.getElementById('page-game');
  if (!container) return;
  container.style.position = 'relative';

  // 顶部枝条装饰
  const topImg = document.createElement('img');
  topImg.src = image;
  topImg.alt = '';
  topImg.className = 'deco-game-top';
  topImg.style.mixBlendMode = 'multiply';
  container.appendChild(topImg);
  activeDecorations.push(topImg);

  // CSS绘制的飘落花瓣
  for (let i = 0; i < 10; i++) {
    const petal = document.createElement('div');
    petal.className = 'deco-petal-css';
    petal.style.left = `${Math.random() * 100}%`;
    petal.style.animationDelay = `${Math.random() * 8}s`;
    petal.style.animationDuration = `${7 + Math.random() * 5}s`;
    const scale = 0.7 + Math.random() * 0.6;
    petal.style.setProperty('--petal-scale', scale);
    container.appendChild(petal);
    activeDecorations.push(petal);
  }
}

/**
 * 游戏页左右两侧装饰
 */
function createGameSidesDecoration(image) {
  const container = document.getElementById('page-game');
  if (!container) return;
  container.style.position = 'relative';

  // 左侧
  const leftImg = document.createElement('img');
  leftImg.src = image;
  leftImg.alt = '';
  leftImg.className = 'deco-game-side deco-game-left';
  leftImg.style.mixBlendMode = 'multiply';
  container.appendChild(leftImg);
  activeDecorations.push(leftImg);

  // 右侧
  const rightImg = document.createElement('img');
  rightImg.src = image;
  rightImg.alt = '';
  rightImg.className = 'deco-game-side deco-game-right';
  rightImg.style.mixBlendMode = 'multiply';
  rightImg.style.transform = 'scaleX(-1)';
  container.appendChild(rightImg);
  activeDecorations.push(rightImg);
}

/**
 * 日历页蝙蝠飞行动画（暗黑哥特主题）
 */
function createFlyingBats(containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;
  container.style.position = 'relative';
  for (let i = 0; i < 2; i++) {
    const bat = document.createElement('span');
    bat.className = 'deco-bat';
    bat.textContent = '🦇';
    bat.style.animationDelay = `${i * 4}s`;
    bat.style.top = `${8 + i * 14}px`;
    container.appendChild(bat);
    activeDecorations.push(bat);
  }
}

/**
 * 获取计时完成庆祝图片（供 timer.js 调用）
 */
export function getTimerCelebrationImage() {
  const wardrobe = getWardrobe();
  const rule = DECORATION_RULES.find(r => r.position === 'timer-celebration');
  if (rule && wardrobe[rule.dimension] === rule.theme) {
    return rule.image;
  }
  return null;
}

/**
 * 获取任务勾选框装饰图片（供 home.js 调用）
 */
export function getTaskCheckboxImage() {
  const wardrobe = getWardrobe();
  const rules = DECORATION_RULES.filter(r => r.position === 'task-checkbox');
  for (const rule of rules) {
    if (wardrobe[rule.dimension] === rule.theme) {
      return rule.image;
    }
  }
  return null;
}

/**
 * 获取引用横幅装饰图片（供 home.js 调用）
 */
export function getQuoteDecorationImage() {
  const wardrobe = getWardrobe();
  const rule = DECORATION_RULES.find(r => r.position === 'quote-right');
  if (rule && wardrobe[rule.dimension] === rule.theme) {
    return rule.image;
  }
  return null;
}
