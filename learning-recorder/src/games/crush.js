/**
 * 情绪粉碎机 - 写下烦恼，选择方式销毁它
 * 4种销毁方式：燃烧、粉碎、吹散、溶解
 * 带音效反馈
 */

let cleanupFn = null;
let timeDisplayEl = null;
let audioCtx = null;
let activeIntervals = new Set();
let activeTimeouts = new Set();

function startTrackedInterval(fn, delay) {
  const id = setInterval(fn, delay);
  activeIntervals.add(id);
  return id;
}

function stopTrackedInterval(id) {
  clearInterval(id);
  activeIntervals.delete(id);
}

function startTrackedTimeout(fn, delay) {
  const id = setTimeout(() => {
    activeTimeouts.delete(id);
    fn();
  }, delay);
  activeTimeouts.add(id);
  return id;
}

function clearRuntimeTimers() {
  activeIntervals.forEach(id => clearInterval(id));
  activeIntervals.clear();
  activeTimeouts.forEach(id => clearTimeout(id));
  activeTimeouts.clear();
}

export function setTimeDisplay(el) {
  timeDisplayEl = el;
}

/**
 * 初始化音频上下文
 */
function initAudio() {
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  }
}

/**
 * 播放燃烧音效 - 噼啪声
 */
function playBurnSound() {
  initAudio();
  const duration = 2.0;
  const bufferSize = audioCtx.sampleRate * duration;
  const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
  const data = buffer.getChannelData(0);
  
  for (let i = 0; i < bufferSize; i++) {
    const t = i / audioCtx.sampleRate;
    // 噼啪噪声
    const crackle = Math.random() * Math.exp(-t * 2) * 0.5;
    // 低频轰鸣
    const rumble = Math.sin(t * 50 * Math.PI * 2) * 0.1 * Math.exp(-t * 1.5);
    data[i] = (crackle + rumble) * 0.3;
  }
  
  const source = audioCtx.createBufferSource();
  source.buffer = buffer;
  
  const filter = audioCtx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.value = 800;
  
  source.connect(filter);
  filter.connect(audioCtx.destination);
  source.start();
}

/**
 * 播放粉碎音效 - 机械破碎声
 */
function playShredSound() {
  initAudio();
  const duration = 1.5;
  const bufferSize = audioCtx.sampleRate * duration;
  const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
  const data = buffer.getChannelData(0);
  
  for (let i = 0; i < bufferSize; i++) {
    const t = i / audioCtx.sampleRate;
    // 金属碰撞声
    const metal = Math.random() * Math.exp(-t * 3) * 0.6;
    // 齿轮转动
    const gear = Math.sin(t * 120 * Math.PI * 2) * 0.15 * Math.exp(-t * 2);
    data[i] = (metal + gear) * 0.25;
  }
  
  const source = audioCtx.createBufferSource();
  source.buffer = buffer;
  
  const filter = audioCtx.createBiquadFilter();
  filter.type = 'highpass';
  filter.frequency.value = 500;
  
  source.connect(filter);
  filter.connect(audioCtx.destination);
  source.start();
}

/**
 * 播放吹散音效 - 风声
 */
function playBlowSound() {
  initAudio();
  const duration = 2.0;
  const bufferSize = audioCtx.sampleRate * duration;
  const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
  const data = buffer.getChannelData(0);
  
  for (let i = 0; i < bufferSize; i++) {
    const t = i / audioCtx.sampleRate;
    // 风声（带通滤波噪声）
    const wind = Math.random() * 2 - 1;
    // 强度包络
    const envelope = Math.sin(t / duration * Math.PI) * 0.4;
    data[i] = wind * envelope;
  }
  
  const source = audioCtx.createBufferSource();
  source.buffer = buffer;
  
  const filter = audioCtx.createBiquadFilter();
  filter.type = 'bandpass';
  filter.frequency.value = 600;
  filter.Q.value = 0.5;
  
  source.connect(filter);
  filter.connect(audioCtx.destination);
  source.start();
}

/**
 * 播放溶解音效 - 水泡声
 */
function playDissolveSound() {
  initAudio();
  const duration = 2.5;
  
  // 创建多个水泡声
  for (let i = 0; i < 8; i++) {
    startTrackedTimeout(() => {
      const osc = audioCtx.createOscillator();
      const gain = audioCtx.createGain();
      
      osc.type = 'sine';
      osc.frequency.value = 200 + Math.random() * 400;
      
      gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.3);
      
      osc.connect(gain);
      gain.connect(audioCtx.destination);
      
      osc.start();
      osc.stop(audioCtx.currentTime + 0.3);
    }, i * 250);
  }
}

/**
 * 初始化情绪粉碎机游戏
 * @param {HTMLElement} container - 游戏容器
 * @returns {Function} 清理函数
 */
export function initCrushGame(container) {
  clearRuntimeTimers();

  // 渲染游戏UI
  container.innerHTML = `
    <div class="crush-game">
      <div class="crush-header">
        <div class="crush-header-icon">💭</div>
        <h2 class="crush-header-title">情绪粉碎机</h2>
        <p class="crush-header-subtitle">写下烦恼，选择方式销毁它</p>
      </div>

      <div class="crush-input-section">
        <textarea class="crush-textarea" id="crush-textarea"
          placeholder="在这里写下让你烦恼的事情..."
          maxlength="200"></textarea>
        <div class="crush-input-footer">
          <span class="crush-char-count"><span id="crush-char-count">0</span>/200</span>
        </div>
      </div>

      <div class="crush-methods-section">
        <h3 class="crush-section-title">选择销毁方式</h3>
        <div class="crush-method-grid">
          <button class="crush-method-btn" data-method="burn">
            <div class="crush-method-icon-wrap">
              <span class="crush-method-icon">🔥</span>
            </div>
            <span class="crush-method-name">燃烧</span>
            <span class="crush-method-desc">让火焰吞噬一切</span>
          </button>
          <button class="crush-method-btn" data-method="shred">
            <div class="crush-method-icon-wrap">
              <span class="crush-method-icon">⚙️</span>
            </div>
            <span class="crush-method-name">粉碎</span>
            <span class="crush-method-desc">撕成碎片随风散去</span>
          </button>
          <button class="crush-method-btn" data-method="blow">
            <div class="crush-method-icon-wrap">
              <span class="crush-method-icon">💨</span>
            </div>
            <span class="crush-method-name">吹散</span>
            <span class="crush-method-desc">一口气吹走烦恼</span>
          </button>
          <button class="crush-method-btn" data-method="dissolve">
            <div class="crush-method-icon-wrap">
              <span class="crush-method-icon">💧</span>
            </div>
            <span class="crush-method-name">溶解</span>
            <span class="crush-method-desc">让水滴慢慢融化</span>
          </button>
        </div>
      </div>

      <div class="crush-canvas-section" id="crush-canvas-section" style="display:none;">
        <canvas id="crush-canvas"></canvas>
        <div class="crush-animation-text" id="crush-anim-text"></div>
        <button class="crush-back-btn" id="crush-back-btn">
          <span>←</span> 继续写
        </button>
      </div>

      <div class="crush-history-section" id="crush-history">
        <h3 class="crush-section-title">🎉 已销毁的烦恼</h3>
        <div class="crush-history-list" id="crush-history-list"></div>
      </div>
    </div>
  `;

  // 绑定事件
  const textarea = document.getElementById('crush-textarea');
  const charCount = document.getElementById('crush-char-count');

  textarea.addEventListener('input', () => {
    charCount.textContent = textarea.value.length;
  });

  // 销毁方式按钮
  document.querySelectorAll('.crush-method-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const text = textarea.value.trim();
      if (!text) {
        textarea.classList.add('shake');
        textarea.placeholder = '先写下你的烦恼吧...';
        startTrackedTimeout(() => textarea.classList.remove('shake'), 500);
        return;
      }
      startDestruction(text, btn.dataset.method);
    });
  });

  // 返回按钮
  document.getElementById('crush-back-btn').addEventListener('click', () => {
    backToInput();
  });

  // 渲染历史记录
  renderHistory();

  cleanupFn = () => {
    clearRuntimeTimers();
    if (audioCtx) {
      audioCtx.close().catch(() => {});
      audioCtx = null;
    }
    timeDisplayEl = null;
  };
  return cleanupFn;
}

/**
 * 开始销毁动画
 */
function startDestruction(text, method) {
  clearRuntimeTimers();

  const canvasSection = document.getElementById('crush-canvas-section');
  const inputSection = document.querySelector('.crush-input-section');
  const methodsSection = document.querySelector('.crush-methods-section');
  const headerSection = document.querySelector('.crush-header');
  const canvas = document.getElementById('crush-canvas');
  const animText = document.getElementById('crush-anim-text');

  // 隐藏输入区域，显示画布
  inputSection.style.display = 'none';
  methodsSection.style.display = 'none';
  headerSection.style.display = 'none';
  canvasSection.style.display = 'flex';

  // 设置画布尺寸
  const rect = canvasSection.getBoundingClientRect();
  canvas.width = rect.width;
  canvas.height = rect.height;

  const ctx = canvas.getContext('2d');

  // 显示动画文字
  animText.textContent = text;
  animText.className = 'crush-animation-text';

  // 播放对应音效
  switch (method) {
    case 'burn':
      playBurnSound();
      animateBurn(ctx, canvas, text, animText);
      break;
    case 'shred':
      playShredSound();
      animateShred(ctx, canvas, text, animText);
      break;
    case 'blow':
      playBlowSound();
      animateBlow(ctx, canvas, text, animText);
      break;
    case 'dissolve':
      playDissolveSound();
      animateDissolve(ctx, canvas, text, animText);
      break;
  }

  // 保存到历史
  saveToHistory(text, method);
}

/**
 * 燃烧动画 - 文字从底部开始燃烧，化为灰烬
 */
function animateBurn(ctx, canvas, text, animText) {
  const particles = [];
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;

  // 创建火焰粒子
  animText.style.opacity = '1';
  animText.style.color = '#FF6B35';

  let frame = 0;
  const maxFrames = 120;

  // 文字渐变为燃烧效果
  const burnInterval = startTrackedInterval(() => {
    frame++;
    const progress = frame / maxFrames;

    // 文字颜色变化：白 -> 橙 -> 红 -> 暗红 -> 消失
    if (progress < 0.3) {
      animText.style.color = '#FF6B35';
      animText.style.textShadow = '0 0 10px #FF6B35, 0 0 20px #FF4500';
    } else if (progress < 0.6) {
      animText.style.color = '#FF4500';
      animText.style.textShadow = '0 0 15px #FF4500, 0 0 30px #DC143C';
      animText.style.transform = `scale(${1 + progress * 0.1})`;
    } else if (progress < 0.8) {
      animText.style.color = '#8B0000';
      animText.style.textShadow = '0 0 5px #8B0000';
      animText.style.opacity = String(1 - (progress - 0.6) * 3);
    } else {
      animText.style.opacity = '0';
    }

    // 生成火焰粒子
    if (progress < 0.7 && frame % 2 === 0) {
      for (let i = 0; i < 3; i++) {
        particles.push({
          x: centerX + (Math.random() - 0.5) * 200,
          y: centerY + (Math.random() - 0.5) * 60,
          vx: (Math.random() - 0.5) * 2,
          vy: -Math.random() * 3 - 1,
          size: Math.random() * 6 + 2,
          life: 1,
          decay: Math.random() * 0.03 + 0.01,
          color: Math.random() > 0.5 ? '#FF6B35' : '#FFD700'
        });
      }
    }

    // 灰烬粒子（后期）
    if (progress > 0.5 && frame % 3 === 0) {
      particles.push({
        x: centerX + (Math.random() - 0.5) * 150,
        y: centerY + (Math.random() - 0.5) * 40,
        vx: (Math.random() - 0.5) * 1,
        vy: -Math.random() * 1.5 - 0.5,
        size: Math.random() * 3 + 1,
        life: 1,
        decay: Math.random() * 0.02 + 0.005,
        color: '#555'
      });
    }

    // 绘制粒子
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (let i = particles.length - 1; i >= 0; i--) {
      const p = particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.life -= p.decay;
      p.size *= 0.98;

      if (p.life <= 0) {
        particles.splice(i, 1);
        continue;
      }

      ctx.globalAlpha = p.life;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    if (frame >= maxFrames) {
      stopTrackedInterval(burnInterval);
      showComplete('烦恼已被火焰吞噬 🔥');
    }
  }, 1000 / 30);
}

/**
 * 粉碎动画 - 文字碎裂成碎片飞散
 */
function animateShred(ctx, canvas, text, animText) {
  const fragments = [];
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;

  animText.style.opacity = '1';

  let frame = 0;
  const maxFrames = 90;

  const shredInterval = startTrackedInterval(() => {
    frame++;
    const progress = frame / maxFrames;

    if (progress < 0.2) {
      // 震动阶段
      const shake = Math.sin(frame * 2) * 3;
      animText.style.transform = `translateX(${shake}px)`;
    } else if (progress < 0.4) {
      // 碎裂阶段
      const fadeProgress = (progress - 0.2) / 0.2;
      animText.style.opacity = String(1 - fadeProgress);
      animText.style.transform = `scale(${1 + fadeProgress * 0.3})`;

      // 生成碎片
      if (frame % 2 === 0) {
        for (let i = 0; i < 5; i++) {
          fragments.push({
            x: centerX + (Math.random() - 0.5) * 180,
            y: centerY + (Math.random() - 0.5) * 40,
            vx: (Math.random() - 0.5) * 8,
            vy: (Math.random() - 0.5) * 8,
            rotation: Math.random() * Math.PI * 2,
            rotSpeed: (Math.random() - 0.5) * 0.3,
            width: Math.random() * 12 + 4,
            height: Math.random() * 8 + 3,
            life: 1,
            decay: Math.random() * 0.015 + 0.005,
            color: ['#333', '#666', '#999', '#FF6B6B', '#4ECDC4'][Math.floor(Math.random() * 5)]
          });
        }
      }
    } else {
      animText.style.opacity = '0';
    }

    // 绘制碎片
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (let i = fragments.length - 1; i >= 0; i--) {
      const f = fragments[i];
      f.x += f.vx;
      f.y += f.vy;
      f.vy += 0.1; // 重力
      f.rotation += f.rotSpeed;
      f.life -= f.decay;

      if (f.life <= 0) {
        fragments.splice(i, 1);
        continue;
      }

      ctx.save();
      ctx.globalAlpha = f.life;
      ctx.translate(f.x, f.y);
      ctx.rotate(f.rotation);
      ctx.fillStyle = f.color;
      ctx.fillRect(-f.width / 2, -f.height / 2, f.width, f.height);
      ctx.restore();
    }
    ctx.globalAlpha = 1;

    if (frame >= maxFrames) {
      stopTrackedInterval(shredInterval);
      showComplete('烦恼已化为碎片 ⚙️');
    }
  }, 1000 / 30);
}

/**
 * 吹散动画 - 文字像沙子一样被风吹散
 */
function animateBlow(ctx, canvas, text, animText) {
  const particles = [];
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;

  animText.style.opacity = '1';

  let frame = 0;
  const maxFrames = 100;
  let blowStarted = false;

  const blowInterval = startTrackedInterval(() => {
    frame++;
    const progress = frame / maxFrames;

    if (progress < 0.3) {
      // 等待阶段，文字微微颤抖
      const shake = Math.sin(frame * 3) * 2;
      animText.style.transform = `translateX(${shake}px)`;
    } else if (progress < 0.5) {
      // 开始吹散
      blowStarted = true;
      const fadeProgress = (progress - 0.3) / 0.2;
      animText.style.opacity = String(1 - fadeProgress * 0.5);

      // 生成风粒子
      if (frame % 2 === 0) {
        for (let i = 0; i < 4; i++) {
          particles.push({
            x: centerX + (Math.random() - 0.5) * 200,
            y: centerY + (Math.random() - 0.5) * 60,
            vx: Math.random() * 6 + 2,
            vy: (Math.random() - 0.5) * 2,
            size: Math.random() * 4 + 2,
            life: 1,
            decay: Math.random() * 0.02 + 0.01,
            color: '#B0B0B0'
          });
        }
      }
    } else {
      animText.style.opacity = '0';
    }

    // 绘制粒子
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (let i = particles.length - 1; i >= 0; i--) {
      const p = particles[i];
      p.x += p.vx;
      p.y += p.vy;
      p.life -= p.decay;
      p.size *= 0.99;

      if (p.life <= 0) {
        particles.splice(i, 1);
        continue;
      }

      ctx.globalAlpha = p.life * 0.6;
      ctx.fillStyle = p.color;
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    if (frame >= maxFrames) {
      stopTrackedInterval(blowInterval);
      showComplete('烦恼已被风吹散 💨');
    }
  }, 1000 / 30);
}

/**
 * 溶解动画 - 文字像糖一样慢慢融化
 */
function animateDissolve(ctx, canvas, text, animText) {
  const drops = [];
  const centerX = canvas.width / 2;
  const centerY = canvas.height / 2;

  animText.style.opacity = '1';

  let frame = 0;
  const maxFrames = 150;

  const dissolveInterval = startTrackedInterval(() => {
    frame++;
    const progress = frame / maxFrames;

    if (progress < 0.4) {
      // 文字开始变透明，边缘模糊
      const fadeProgress = progress / 0.4;
      animText.style.opacity = String(1 - fadeProgress * 0.3);
      animText.style.filter = `blur(${fadeProgress * 2}px)`;
      animText.style.transform = `scale(${1 + fadeProgress * 0.05})`;

      // 生成水滴
      if (frame % 3 === 0) {
        for (let i = 0; i < 2; i++) {
          drops.push({
            x: centerX + (Math.random() - 0.5) * 160,
            y: centerY + (Math.random() - 0.5) * 50,
            vx: (Math.random() - 0.5) * 0.5,
            vy: Math.random() * 1.5 + 0.5,
            size: Math.random() * 8 + 4,
            life: 1,
            decay: Math.random() * 0.01 + 0.005,
            color: '#4ECDC4'
          });
        }
      }
    } else if (progress < 0.7) {
      animText.style.opacity = String(1 - (progress - 0.4) / 0.3);
      animText.style.filter = `blur(${2 + (progress - 0.4) / 0.3 * 3}px)`;
    } else {
      animText.style.opacity = '0';
    }

    // 绘制水滴
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    for (let i = drops.length - 1; i >= 0; i--) {
      const d = drops[i];
      d.x += d.vx;
      d.y += d.vy;
      d.vy += 0.05; // 重力
      d.life -= d.decay;
      d.size *= 0.99;

      if (d.life <= 0) {
        drops.splice(i, 1);
        continue;
      }

      ctx.globalAlpha = d.life * 0.7;
      ctx.fillStyle = d.color;
      ctx.beginPath();
      ctx.arc(d.x, d.y, d.size, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;

    if (frame >= maxFrames) {
      stopTrackedInterval(dissolveInterval);
      showComplete('烦恼已慢慢溶解 💧');
    }
  }, 1000 / 30);
}

/**
 * 显示完成提示
 */
function showComplete(message) {
  const animText = document.getElementById('crush-anim-text');
  animText.textContent = message;
  animText.className = 'crush-animation-text crush-complete';
  animText.style.opacity = '1';
  animText.style.filter = 'none';
  animText.style.transform = 'none';
}

/**
 * 返回输入界面
 */
function backToInput() {
  clearRuntimeTimers();

  const canvasSection = document.getElementById('crush-canvas-section');
  const inputSection = document.querySelector('.crush-input-section');
  const methodsSection = document.querySelector('.crush-methods-section');
  const headerSection = document.querySelector('.crush-header');

  canvasSection.style.display = 'none';
  inputSection.style.display = 'block';
  methodsSection.style.display = 'block';
  headerSection.style.display = 'block';

  // 清空画布
  const canvas = document.getElementById('crush-canvas');
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
}

/**
 * 保存到历史记录
 */
function saveToHistory(text, method) {
  const history = JSON.parse(localStorage.getItem('crush-history') || '[]');
  history.unshift({
    text: text,
    method: method,
    timestamp: Date.now()
  });
  // 只保留最近20条
  if (history.length > 20) {
    history.length = 20;
  }
  localStorage.setItem('crush-history', JSON.stringify(history));
  renderHistory();
}

/**
 * 渲染历史记录
 */
function renderHistory() {
  const historyList = document.getElementById('crush-history-list');
  if (!historyList) return;

  const history = JSON.parse(localStorage.getItem('crush-history') || '[]');
  
  if (history.length === 0) {
    historyList.innerHTML = '<div class="crush-history-empty">还没有销毁过烦恼哦～</div>';
    return;
  }

  const methodIcons = {
    burn: '🔥',
    shred: '⚙️',
    blow: '💨',
    dissolve: '💧'
  };

  const methodNames = {
    burn: '燃烧',
    shred: '粉碎',
    blow: '吹散',
    dissolve: '溶解'
  };

  historyList.innerHTML = history.map(item => {
    const date = new Date(item.timestamp);
    const dateStr = `${date.getMonth() + 1}月${date.getDate()}日 ${date.getHours().toString().padStart(2, '0')}:${date.getMinutes().toString().padStart(2, '0')}`;
    return `
      <div class="crush-history-item">
        <div class="crush-history-text">${item.text}</div>
        <div class="crush-history-meta">
          <span class="crush-history-method">${methodIcons[item.method]} ${methodNames[item.method]}</span>
          <span class="crush-history-time">${dateStr}</span>
        </div>
      </div>
    `;
  }).join('');
}
