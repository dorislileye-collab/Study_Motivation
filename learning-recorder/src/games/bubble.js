/**
 * 泡泡星球小游戏 - Canvas物理碰撞泡泡
 * 点击产生泡泡，双击戳破（粒子爆裂）
 */
import { store } from '../store.js';

let canvas, ctx, animId;
let bubbles = [];
let particles = [];
let isRunning = false;
let timeDisplayEl = null;

// 音效上下文
let audioCtx = null;

function getAudioCtx() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  return audioCtx;
}

/** 碰撞弹性音 */
function playBounceSound() {
  try {
    const ctx = getAudioCtx();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.setValueAtTime(300 + Math.random() * 200, ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(150, ctx.currentTime + 0.1);
    gain.gain.setValueAtTime(0.08, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1);
    osc.type = 'sine';
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.1);
  } catch (e) {}
}

/** 戳破"啵"声 */
function playPopSound() {
  try {
    const ctx = getAudioCtx();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.setValueAtTime(600, ctx.currentTime);
    osc.frequency.exponentialRampToValueAtTime(100, ctx.currentTime + 0.08);
    gain.gain.setValueAtTime(0.15, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.08);
    osc.type = 'sine';
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.08);
  } catch (e) {}
}

/** 泡泡类 */
class Bubble {
  constructor(x, y, radius) {
    this.x = x;
    this.y = y;
    this.radius = radius || 15 + Math.random() * 25;
    this.vx = (Math.random() - 0.5) * 3;
    this.vy = (Math.random() - 0.5) * 3;
    this.hue = Math.random() * 360;
    this.color = `hsla(${this.hue}, 70%, 60%, 0.6)`;
    this.strokeColor = `hsla(${this.hue}, 70%, 70%, 0.9)`;
    this.opacity = 1;
    this.wobble = Math.random() * Math.PI * 2;
  }

  update(width, height) {
    this.wobble += 0.05;
    this.x += this.vx + Math.sin(this.wobble) * 0.3;
    this.y += this.vy + Math.cos(this.wobble) * 0.2;

    // 边界碰撞
    if (this.x - this.radius < 0) {
      this.x = this.radius;
      this.vx = Math.abs(this.vx) * 0.8;
      playBounceSound();
    }
    if (this.x + this.radius > width) {
      this.x = width - this.radius;
      this.vx = -Math.abs(this.vx) * 0.8;
      playBounceSound();
    }
    if (this.y - this.radius < 0) {
      this.y = this.radius;
      this.vy = Math.abs(this.vy) * 0.8;
      playBounceSound();
    }
    if (this.y + this.radius > height) {
      this.y = height - this.radius;
      this.vy = -Math.abs(this.vy) * 0.8;
      playBounceSound();
    }
  }

  draw(ctx) {
    ctx.save();
    ctx.globalAlpha = this.opacity;

    // 泡泡主体
    const gradient = ctx.createRadialGradient(
      this.x - this.radius * 0.3, this.y - this.radius * 0.3, 0,
      this.x, this.y, this.radius
    );
    gradient.addColorStop(0, `hsla(${this.hue}, 80%, 85%, 0.8)`);
    gradient.addColorStop(0.7, this.color);
    gradient.addColorStop(1, `hsla(${this.hue}, 70%, 50%, 0.3)`);

    ctx.beginPath();
    ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
    ctx.fillStyle = gradient;
    ctx.fill();

    // 边框
    ctx.strokeStyle = this.strokeColor;
    ctx.lineWidth = 1.5;
    ctx.stroke();

    // 高光
    ctx.beginPath();
    ctx.arc(this.x - this.radius * 0.3, this.y - this.radius * 0.3, this.radius * 0.15, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255,255,255,0.7)';
    ctx.fill();

    ctx.restore();
  }
}

/** 爆裂粒子类 */
class Particle {
  constructor(x, y, hue) {
    this.x = x;
    this.y = y;
    const angle = Math.random() * Math.PI * 2;
    const speed = 2 + Math.random() * 5;
    this.vx = Math.cos(angle) * speed;
    this.vy = Math.sin(angle) * speed;
    this.radius = 2 + Math.random() * 4;
    this.hue = hue;
    this.life = 1;
    this.decay = 0.02 + Math.random() * 0.03;
  }

  update() {
    this.x += this.vx;
    this.y += this.vy;
    this.vy += 0.1; // 重力
    this.life -= this.decay;
  }

  draw(ctx) {
    ctx.save();
    ctx.globalAlpha = Math.max(0, this.life);
    const r = Math.max(0, this.radius * this.life);
    if (r <= 0) { ctx.restore(); return; }
    ctx.beginPath();
    ctx.arc(this.x, this.y, r, 0, Math.PI * 2);
    ctx.fillStyle = `hsla(${this.hue}, 70%, 60%, ${this.life})`;
    ctx.fill();
    ctx.restore();
  }
}

/** 碰撞检测 */
function checkCollisions() {
  for (let i = 0; i < bubbles.length; i++) {
    for (let j = i + 1; j < bubbles.length; j++) {
      const a = bubbles[i], b = bubbles[j];
      const dx = b.x - a.x;
      const dy = b.y - a.y;
      const dist = Math.sqrt(dx * dx + dy * dy);
      const minDist = a.radius + b.radius;

      if (dist < minDist && dist > 0) {
        // 分离
        const overlap = (minDist - dist) / 2;
        const nx = dx / dist;
        const ny = dy / dist;
        a.x -= nx * overlap;
        a.y -= ny * overlap;
        b.x += nx * overlap;
        b.y += ny * overlap;

        // 弹性碰撞
        const dvx = a.vx - b.vx;
        const dvy = a.vy - b.vy;
        const dotProduct = dvx * nx + dvy * ny;

        if (dotProduct > 0) {
          a.vx -= dotProduct * nx * 0.5;
          a.vy -= dotProduct * ny * 0.5;
          b.vx += dotProduct * nx * 0.5;
          b.vy += dotProduct * ny * 0.5;
        }
      }
    }
  }
}

/** 戳破泡泡 */
function popBubble(bubble) {
  playPopSound();
  // 产生爆裂粒子
  for (let i = 0; i < 12; i++) {
    particles.push(new Particle(bubble.x, bubble.y, bubble.hue));
  }
  // 移除泡泡
  const idx = bubbles.indexOf(bubble);
  if (idx > -1) bubbles.splice(idx, 1);
}

/** 初始化泡泡游戏 */
export function initBubbleGame(container) {
  canvas = document.createElement('canvas');
  canvas.className = 'bubble-canvas';
  canvas.style.width = '100%';
  canvas.style.height = '100%';
  canvas.style.display = 'block';
  canvas.style.touchAction = 'none';
  container.appendChild(canvas);

  ctx = canvas.getContext('2d');
  resizeCanvas();

  // 事件绑定
  let lastTapTime = 0;
  let lastTapPos = { x: 0, y: 0 };

  function handleTap(x, y) {
    const now = Date.now();
    const timeDiff = now - lastTapTime;
    const dx = x - lastTapPos.x;
    const dy = y - lastTapPos.y;
    const dist = Math.sqrt(dx * dx + dy * dy);

    if (timeDiff < 300 && dist < 30) {
      // 双击 - 戳破最近的泡泡
      const bubble = findBubbleAt(x, y);
      if (bubble) {
        popBubble(bubble);
      }
    } else {
      // 单击 - 创建新泡泡
      if (bubbles.length < 30) { // 限制最大数量
        bubbles.push(new Bubble(x, y));
      }
    }

    lastTapTime = now;
    lastTapPos = { x, y };
  }

  canvas.addEventListener('pointerdown', (e) => {
    const rect = canvas.getBoundingClientRect();
    handleTap(e.clientX - rect.left, e.clientY - rect.top);
  });

  // 初始泡泡
  for (let i = 0; i < 5; i++) {
    bubbles.push(new Bubble(
      canvas.width * (0.2 + Math.random() * 0.6),
      canvas.height * (0.2 + Math.random() * 0.6)
    ));
  }

  isRunning = true;
  animate();

  // 返回清理函数
  return () => {
    isRunning = false;
    if (animId) cancelAnimationFrame(animId);
    canvas.remove();
  };
}

function findBubbleAt(x, y) {
  for (let i = bubbles.length - 1; i >= 0; i--) {
    const b = bubbles[i];
    const dx = x - b.x;
    const dy = y - b.y;
    if (Math.sqrt(dx * dx + dy * dy) < b.radius) {
      return b;
    }
  }
  return null;
}

function resizeCanvas() {
  if (!canvas) return;
  const parent = canvas.parentElement;
  canvas.width = parent.clientWidth;
  canvas.height = parent.clientHeight;
}

function animate() {
  if (!isRunning) return;

  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // 更新和绘制泡泡
  bubbles.forEach(b => {
    b.update(canvas.width, canvas.height);
    b.draw(ctx);
  });

  // 碰撞检测
  checkCollisions();

  // 更新和绘制粒子
  particles = particles.filter(p => p.life > 0);
  particles.forEach(p => {
    p.update();
    p.draw(ctx);
  });

  animId = requestAnimationFrame(animate);
}

function updateTimeDisplay() {
  if (!timeDisplayEl) return;
  const remainingSec = Math.max(0, 20 * 60 - store.getGameTimeToday());
  const mins = Math.floor(remainingSec / 60);
  const secs = remainingSec % 60;
  timeDisplayEl.textContent = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

export function setTimeDisplay(el) {
  timeDisplayEl = el;
}
