/**
 * 沙画禅境小游戏 - Canvas粒子系统（优化版）
 * 性能优化：requestAnimationFrame + 粒子池 + 最大2000粒子
 * 视觉优化：更鲜艳的粒子、更持久的轨迹、环境粒子、发光效果
 */
import { store } from '../store.js';

// ========== 材质定义（优化色彩和物理） ==========
const MATERIALS = {
  sand: {
    name: '细沙',
    icon: '🏖️',
    colors: ['#F4D03F', '#E67E22', '#D4A574', '#F39C12', '#FDEBD0', '#EDBB99', '#F5CBA7'],
    size: [2, 5],
    spread: 4,
    gravity: 0.12,
    opacity: 0.9,
    trail: 0.006, // 轨迹非常持久
  },
  powder: {
    name: '彩色粉末',
    icon: '🎨',
    colors: ['#FF1744', '#FF9100', '#FFEA00', '#00E676', '#00B0FF', '#D500F9', '#F50057', '#76FF03'],
    size: [3, 7],
    spread: 6,
    gravity: 0.06,
    opacity: 0.85,
    trail: 0.005,
    glow: true,
  },
  star: {
    name: '星空粒子',
    icon: '✨',
    colors: ['#7C4DFF', '#448AFF', '#18FFFF', '#E040FB', '#FF4081', '#FFD740', '#69F0AE'],
    size: [2, 6],
    spread: 5,
    gravity: 0.03,
    opacity: 1,
    trail: 0.004,
    glow: true,
    twinkle: true, // 闪烁效果
  },
  water: {
    name: '水滴',
    icon: '💧',
    colors: ['#00BCD4', '#0097A7', '#4DD0E1', '#80DEEA', '#B2EBF2', '#E0F7FA'],
    size: [5, 10],
    spread: 3,
    gravity: 0.18,
    opacity: 0.6,
    trail: 0.007,
  },
};

// ========== 游戏状态 ==========
let canvas = null;
let ctx = null;
let particles = [];
let ambientParticles = []; // 环境粒子
let isDrawing = false;
let lastX = 0;
let lastY = 0;
let currentMaterial = 'sand';
let animFrameId = null;
let sandNoiseNode = null;
let sandGainNode = null;
let audioCtx = null;
let gameArea = null;
let timeDisplay = null;
let timeInterval = null;
let isFrozen = false;
let frameCount = 0;

const MAX_PARTICLES = 2000;
const MAX_AMBIENT = 50;

// ========== 初始化 ==========
export function initSandGame(container) {
  gameArea = container;
  isFrozen = false;
  frameCount = 0;

  // 创建Canvas
  canvas = document.createElement('canvas');
  canvas.className = 'sand-canvas';
  gameArea.appendChild(canvas);

  // 调整Canvas尺寸
  resizeCanvas();
  window.addEventListener('resize', resizeCanvas);

  ctx = canvas.getContext('2d');

  // 初始化音频
  initAudio();

  // 初始化环境粒子
  initAmbientParticles();

  // 绑定事件
  bindEvents();

  // 启动渲染
  startRender();

  // 启动倒计时
  startCountdown();

  return () => cleanup();
}

/** 调整Canvas尺寸 */
function resizeCanvas() {
  if (!canvas || !gameArea) return;
  const rect = gameArea.getBoundingClientRect();
  canvas.width = rect.width;
  canvas.height = rect.height;

  // 重绘背景
  if (ctx) {
    drawBackground();
  }
}

/** 绘制渐变背景 */
function drawBackground() {
  if (!ctx || !canvas) return;
  const gradient = ctx.createLinearGradient(0, 0, 0, canvas.height);
  gradient.addColorStop(0, '#0f0f1a');
  gradient.addColorStop(0.5, '#1a1a2e');
  gradient.addColorStop(1, '#16213e');
  ctx.fillStyle = gradient;
  ctx.fillRect(0, 0, canvas.width, canvas.height);
}

/** 初始化环境粒子（漂浮的微光） */
function initAmbientParticles() {
  ambientParticles = [];
  for (let i = 0; i < MAX_AMBIENT; i++) {
    ambientParticles.push({
      x: Math.random() * (canvas?.width || 400),
      y: Math.random() * (canvas?.height || 600),
      size: 1 + Math.random() * 2,
      speed: 0.2 + Math.random() * 0.5,
      opacity: 0.1 + Math.random() * 0.3,
      phase: Math.random() * Math.PI * 2,
    });
  }
}

/** 初始化音频（沙沙声） */
function initAudio() {
  try {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();

    // 创建白噪音缓冲区
    const bufferSize = 2 * audioCtx.sampleRate;
    const noiseBuffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
    const output = noiseBuffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      output[i] = Math.random() * 2 - 1;
    }

    // 白噪音源
    sandNoiseNode = audioCtx.createBufferSource();
    sandNoiseNode.buffer = noiseBuffer;
    sandNoiseNode.loop = true;

    // 低通滤波器（模拟沙沙声）
    const filter = audioCtx.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = 1200;
    filter.Q.value = 1;

    // 增益控制
    sandGainNode = audioCtx.createGain();
    sandGainNode.gain.value = 0;

    sandNoiseNode.connect(filter);
    filter.connect(sandGainNode);
    sandGainNode.connect(audioCtx.destination);
    sandNoiseNode.start();
  } catch (e) {
    console.warn('音频初始化失败:', e);
  }
}

/** 播放/停止沙沙声 */
function setSandSound(active) {
  if (!sandGainNode) return;
  const targetGain = active ? 0.12 : 0;
  sandGainNode.gain.linearRampToValueAtTime(targetGain, audioCtx.currentTime + 0.05);
}

// ========== 事件绑定 ==========
function bindEvents() {
  // 鼠标事件
  canvas.addEventListener('mousedown', onPointerDown);
  canvas.addEventListener('mousemove', onPointerMove);
  canvas.addEventListener('mouseup', onPointerUp);
  canvas.addEventListener('mouseleave', onPointerUp);

  // 触摸事件
  canvas.addEventListener('touchstart', onPointerDown, { passive: false });
  canvas.addEventListener('touchmove', onPointerMove, { passive: false });
  canvas.addEventListener('touchend', onPointerUp);
  canvas.addEventListener('touchcancel', onPointerUp);

  // 点击产生粒子喷泉
  canvas.addEventListener('click', onClickBurst);
}

function getPointerPos(e) {
  const rect = canvas.getBoundingClientRect();
  const clientX = e.touches ? e.touches[0].clientX : e.clientX;
  const clientY = e.touches ? e.touches[0].clientY : e.clientY;
  return {
    x: clientX - rect.left,
    y: clientY - rect.top,
  };
}

function onPointerDown(e) {
  if (isFrozen) return;
  e.preventDefault();
  isDrawing = true;
  const pos = getPointerPos(e);
  lastX = pos.x;
  lastY = pos.y;
  setSandSound(true);

  // 恢复音频上下文（浏览器策略）
  if (audioCtx && audioCtx.state === 'suspended') {
    audioCtx.resume();
  }

  // 按下时立即产生一簇粒子
  spawnParticles(pos.x, pos.y, 8);
}

function onPointerMove(e) {
  if (!isDrawing || isFrozen) return;
  e.preventDefault();
  const pos = getPointerPos(e);

  // 在两点之间插值生成粒子（防止快速移动时断线）
  const dist = Math.hypot(pos.x - lastX, pos.y - lastY);
  const steps = Math.max(1, Math.floor(dist / 3));

  for (let i = 0; i < steps; i++) {
    const t = i / steps;
    const x = lastX + (pos.x - lastX) * t;
    const y = lastY + (pos.y - lastY) * t;
    spawnParticles(x, y, 5);
  }

  lastX = pos.x;
  lastY = pos.y;
}

function onPointerUp() {
  isDrawing = false;
  setSandSound(false);
}

/** 点击产生粒子喷泉 */
function onClickBurst(e) {
  if (isFrozen) return;
  const pos = getPointerPos(e);
  const mat = MATERIALS[currentMaterial];

  // 更大的喷泉效果
  for (let i = 0; i < 50; i++) {
    const angle = (Math.PI * 2 / 50) * i + Math.random() * 0.3;
    const speed = 3 + Math.random() * 6;
    addParticle(
      pos.x,
      pos.y,
      Math.cos(angle) * speed,
      Math.sin(angle) * speed,
      mat
    );
  }
}

// ========== 粒子系统 ==========
function spawnParticles(x, y, count) {
  const mat = MATERIALS[currentMaterial];

  for (let i = 0; i < count; i++) {
    if (particles.length >= MAX_PARTICLES) {
      // 回收最老的粒子
      particles.shift();
    }

    const color = mat.colors[Math.floor(Math.random() * mat.colors.length)];
    const size = mat.size[0] + Math.random() * (mat.size[1] - mat.size[0]);
    const spread = mat.spread;

    particles.push({
      x: x + (Math.random() - 0.5) * spread,
      y: y + (Math.random() - 0.5) * spread,
      vx: (Math.random() - 0.5) * 3,
      vy: (Math.random() - 0.5) * 3,
      size,
      color,
      opacity: mat.opacity,
      life: 1,
      decay: 0.001 + Math.random() * 0.002, // 更慢的衰减
      glow: mat.glow || false,
      twinkle: mat.twinkle || false,
      phase: Math.random() * Math.PI * 2, // 闪烁相位
    });
  }
}

function addParticle(x, y, vx, vy, mat) {
  if (particles.length >= MAX_PARTICLES) {
    particles.shift();
  }

  const color = mat.colors[Math.floor(Math.random() * mat.colors.length)];
  const size = mat.size[0] + Math.random() * (mat.size[1] - mat.size[0]);

  particles.push({
    x,
    y,
    vx,
    vy,
    size,
    color,
    opacity: mat.opacity,
    life: 1,
    decay: 0.003 + Math.random() * 0.004,
    glow: mat.glow || false,
    twinkle: mat.twinkle || false,
    phase: Math.random() * Math.PI * 2,
  });
}

// ========== 渲染循环 ==========
function startRender() {
  function render() {
    if (!ctx || !canvas) return;

    frameCount++;

    // 获取当前材质的轨迹持久度
    const mat = MATERIALS[currentMaterial];
    const trailAlpha = mat.trail || 0.03;

    // 半透明清除（产生拖尾效果，值越小轨迹越持久）
    ctx.fillStyle = `rgba(15, 15, 26, ${trailAlpha})`;
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // 绘制环境粒子（漂浮微光）
    drawAmbientParticles();

    // 更新和绘制粒子
    for (let i = particles.length - 1; i >= 0; i--) {
      const p = particles[i];

      // 物理更新
      p.vy += mat.gravity * 0.3;
      p.x += p.vx;
      p.y += p.vy;
      p.vx *= 0.97; // 空气阻力
      p.vy *= 0.97;
      p.life -= p.decay;
      p.phase += 0.05; // 闪烁相位更新

      // 边界反弹（更柔和）
      if (p.x < 0) { p.x = 0; p.vx *= -0.3; }
      if (p.x > canvas.width) { p.x = canvas.width; p.vx *= -0.3; }
      if (p.y < 0) { p.y = 0; p.vy *= -0.3; }
      if (p.y > canvas.height) { p.y = canvas.height; p.vy *= -0.3; }

      // 移除死亡粒子
      if (p.life <= 0) {
        particles.splice(i, 1);
        continue;
      }

      // 计算闪烁透明度
      let displayOpacity = p.opacity * p.life;
      if (p.twinkle) {
        displayOpacity *= 0.5 + 0.5 * Math.sin(p.phase);
      }

      // 绘制粒子
      ctx.globalAlpha = displayOpacity;
      ctx.fillStyle = p.color;

      if (p.glow) {
        // 发光效果（降低强度）
        ctx.shadowBlur = 6;
        ctx.shadowColor = p.color;
      } else {
        ctx.shadowBlur = 0;
      }

      // 绘制圆形粒子
      const drawSize = p.size * (0.5 + 0.5 * p.life);
      ctx.beginPath();
      ctx.arc(p.x, p.y, drawSize, 0, Math.PI * 2);
      ctx.fill();
    }

    // 绘制提示文字（当没有粒子时）
    if (particles.length === 0 && frameCount < 300) {
      drawHintText();
    }

    ctx.globalAlpha = 1;
    ctx.shadowBlur = 0;

    animFrameId = requestAnimationFrame(render);
  }

  // 初始化背景
  drawBackground();

  animFrameId = requestAnimationFrame(render);
}

/** 绘制环境粒子 */
function drawAmbientParticles() {
  for (const p of ambientParticles) {
    // 缓慢上浮
    p.y -= p.speed;
    p.phase += 0.02;

    // 循环
    if (p.y < -10) {
      p.y = canvas.height + 10;
      p.x = Math.random() * canvas.width;
    }

    // 闪烁
    const opacity = p.opacity * (0.5 + 0.5 * Math.sin(p.phase));

    ctx.globalAlpha = opacity;
    ctx.fillStyle = '#FFFFFF';
    ctx.beginPath();
    ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
    ctx.fill();
  }
  ctx.globalAlpha = 1;
}

/** 绘制提示文字 */
function drawHintText() {
  const alpha = Math.max(0, 1 - frameCount / 300);
  ctx.globalAlpha = alpha * 0.5;
  ctx.fillStyle = '#FFFFFF';
  ctx.font = '16px sans-serif';
  ctx.textAlign = 'center';
  ctx.fillText('✨ 拖动鼠标开始创作', canvas.width / 2, canvas.height / 2);
  ctx.fillText('点击画布产生粒子喷泉', canvas.width / 2, canvas.height / 2 + 30);
  ctx.globalAlpha = 1;
}

// ========== 倒计时 ==========
function startCountdown() {
  updateCountdownDisplay();

  timeInterval = setInterval(() => {
    const gameTimeUsed = store.getGameTimeToday();
    const maxGameTime = 20 * 60;

    if (gameTimeUsed >= maxGameTime) {
      clearInterval(timeInterval);
      timeInterval = null;
      freezeGame();
      return;
    }

    updateCountdownDisplay();
  }, 1000);
}

function updateCountdownDisplay() {
  if (!timeDisplay) return;
  const remainingSec = Math.max(0, 20 * 60 - store.getGameTimeToday());
  const mins = Math.floor(remainingSec / 60);
  const secs = remainingSec % 60;
  timeDisplay.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

  // 不足5分钟变红
  if (remainingSec < 300) {
    timeDisplay.style.color = '#EF5350';
  }
}

/** 冻结游戏 */
function freezeGame() {
  isFrozen = true;
  isDrawing = false;
  setSandSound(false);

  // 显示冻结提示
  const overlay = document.createElement('div');
  overlay.className = 'game-freeze-overlay';
  overlay.innerHTML = `
    <div class="freeze-content">
      <div class="freeze-icon">⏰</div>
      <h3>今日游戏时间已用完</h3>
      <p>明天再来玩吧！</p>
      <button class="btn-primary" id="btn-sand-exit">退出</button>
    </div>
  `;
  gameArea.appendChild(overlay);

  document.getElementById('btn-sand-exit').addEventListener('click', () => {
    overlay.remove();
    // 返回游戏列表
    import('../game.js').then(m => m.renderGamePage());
  });
}

// ========== 清理 ==========
function cleanup() {
  if (animFrameId) {
    cancelAnimationFrame(animFrameId);
    animFrameId = null;
  }
  if (timeInterval) {
    clearInterval(timeInterval);
    timeInterval = null;
  }
  if (sandNoiseNode) {
    try { sandNoiseNode.stop(); } catch (e) {}
    sandNoiseNode = null;
  }
  if (audioCtx) {
    audioCtx.close();
    audioCtx = null;
  }
  window.removeEventListener('resize', resizeCanvas);
  particles = [];
  ambientParticles = [];
}

// ========== 公开API ==========
export function setMaterial(material) {
  if (MATERIALS[material]) {
    currentMaterial = material;
  }
}

export function resetCanvas() {
  if (!ctx || !canvas) return;
  particles = [];
  frameCount = 0;
  drawBackground();
}

export function setTimeDisplay(el) {
  timeDisplay = el;
}
