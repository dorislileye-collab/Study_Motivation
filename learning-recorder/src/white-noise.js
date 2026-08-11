/**
 * 专注白噪音模块
 * - 雨声/时钟滴答：免费，Web Audio API 程序化生成
 * - 溪流/虫鸣/海浪：付费，使用音频文件
 * - 支持静音、音量调节、无限循环
 */
import { store } from './store.js';

// 白噪音列表
const WHITE_NOISES = [
  { id: 'rain', name: '雨声', icon: '🌧️', price: 0, type: 'generated' },
  { id: 'clock', name: '时钟滴答', icon: '🕐', price: 0, type: 'generated' },
  { id: 'stream', name: '溪流潺潺', icon: '🏞️', price: 150, type: 'audio', file: '/public/audio/rain.mp3' },
  { id: 'crickets', name: '虫鸣夏夜', icon: '', price: 200, type: 'audio', file: '/public/audio/clock.mp3' },
  { id: 'waves', name: '海浪轻拍', icon: '🌊', price: 250, type: 'audio', file: '/public/audio/snow-mountain.mp3' },
];

// 播放状态
let currentId = null;
let currentVolume = 0.5;
let isMuted = false;
let audioEl = null;
let audioCtx = null;
let noiseSource = null;
let noiseGain = null;
let clockInterval = null;

/**
 * 获取所有白噪音
 */
export function getWhiteNoises() {
  return WHITE_NOISES;
}

/**
 * 获取已拥有的付费白噪音
 */
export function getOwnedWhiteNoises() {
  return store.getOwnedWhiteNoises();
}

/**
 * 播放白噪音
 */
export function playWhiteNoise(id) {
  const noise = WHITE_NOISES.find(n => n.id === id);
  if (!noise) return;

  // 付费检查
  if (noise.price > 0) {
    const owned = store.getOwnedWhiteNoises();
    if (!owned.includes(id)) {
      // 尝试购买
      const result = store.spendCoins(noise.price);
      if (!result.success) {
        showToast(`金币不足，需要 ${noise.price} 金币`);
        return;
      }
      store.addOwnedWhiteNoise(id);
    }
  }

  // 先停止当前播放
  stopWhiteNoise();

  currentId = id;
  currentVolume = 0.5;
  isMuted = false;

  if (noise.type === 'generated') {
    if (id === 'rain') {
      startRainSound();
    } else if (id === 'clock') {
      startClockSound();
    }
  } else {
    startAudioPlayback(noise.file);
  }

  // 更新UI
  updateWhiteNoiseUI();
}

/**
 * 停止白噪音
 */
export function stopWhiteNoise() {
  if (audioEl) {
    audioEl.pause();
    audioEl.src = '';
    audioEl = null;
  }

  if (noiseSource) {
    try { noiseSource.stop(); } catch (e) {}
    noiseSource = null;
  }

  if (audioCtx) {
    try { audioCtx.close(); } catch (e) {}
    audioCtx = null;
  }

  if (clockInterval) {
    clearInterval(clockInterval);
    clockInterval = null;
  }

  noiseGain = null;
  currentId = null;
  updateWhiteNoiseUI();
}

/**
 * 设置音量
 */
export function setWhiteNoiseVolume(vol) {
  currentVolume = Math.max(0, Math.min(1, vol));
  if (noiseGain) {
    noiseGain.gain.value = isMuted ? 0 : currentVolume;
  }
  if (audioEl) {
    audioEl.volume = isMuted ? 0 : currentVolume;
  }
}

/**
 * 切换静音
 */
export function toggleMute() {
  isMuted = !isMuted;
  if (noiseGain) {
    noiseGain.gain.value = isMuted ? 0 : currentVolume;
  }
  if (audioEl) {
    audioEl.volume = isMuted ? 0 : currentVolume;
  }
  updateWhiteNoiseUI();
}

/**
 * 是否正在播放
 */
export function isPlaying() {
  return currentId !== null;
}

/**
 * 获取当前播放ID
 */
export function getCurrentId() {
  return currentId;
}

/**
 * 是否静音
 */
export function getIsMuted() {
  return isMuted;
}

/**
 * 获取当前音量
 */
export function getVolume() {
  return currentVolume;
}

// ========== 程序化音频生成 ==========

/**
 * 生成雨声（白噪音 + 低通滤波）
 */
function startRainSound() {
  audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  const bufferSize = 2 * audioCtx.sampleRate;
  const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
  const data = buffer.getChannelData(0);

  // 生成带随机变化的白噪音
  let lastOut = 0;
  for (let i = 0; i < bufferSize; i++) {
    const white = Math.random() * 2 - 1;
    // 棕色噪音（更柔和，像雨声）
    data[i] = (lastOut + (0.02 * white)) / 1.02;
    lastOut = data[i];
    data[i] *= 3.5;
  }

  noiseSource = audioCtx.createBufferSource();
  noiseSource.buffer = buffer;
  noiseSource.loop = true;

  // 低通滤波器，让声音更像雨
  const filter = audioCtx.createBiquadFilter();
  filter.type = 'lowpass';
  filter.frequency.value = 800;

  noiseGain = audioCtx.createGain();
  noiseGain.gain.value = isMuted ? 0 : currentVolume;

  noiseSource.connect(filter);
  filter.connect(noiseGain);
  noiseGain.connect(audioCtx.destination);
  noiseSource.start();
}

/**
 * 生成时钟滴答声
 */
function startClockSound() {
  audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  noiseGain = audioCtx.createGain();
  noiseGain.gain.value = isMuted ? 0 : currentVolume * 0.3;
  noiseGain.connect(audioCtx.destination);

  // 每秒滴答一次
  function tick() {
    if (!audioCtx || audioCtx.state === 'closed') return;
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();

    osc.type = 'sine';
    osc.frequency.value = 800;

    gain.gain.setValueAtTime(isMuted ? 0 : currentVolume * 0.3, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, audioCtx.currentTime + 0.05);

    osc.connect(gain);
    gain.connect(audioCtx.destination);

    osc.start(audioCtx.currentTime);
    osc.stop(audioCtx.currentTime + 0.05);
  }

  tick();
  clockInterval = setInterval(tick, 1000);
}

/**
 * 播放音频文件（无限循环）
 */
function startAudioPlayback(file) {
  audioEl = new Audio(file);
  audioEl.loop = true;
  audioEl.volume = isMuted ? 0 : currentVolume;
  audioEl.play().catch(() => {});
}

// ========== UI ==========

/**
 * 渲染白噪音面板
 */
export function renderWhiteNoisePanel() {
  const owned = store.getOwnedWhiteNoises();

  return `
    <div class="white-noise-panel">
      <div class="wn-header">
        <span class="wn-title">专注白噪音</span>
        ${currentId || isMuted ? `
        <button class="wn-mute-btn" id="wn-mute-btn" title="静音">
          ${isMuted ? '🔇' : '🔊'}
        </button>
      ` : ''}
      </div>
      <div class="wn-list">
        ${WHITE_NOISES.map(n => {
          const isActive = currentId === n.id;
          const isOwned = n.price === 0 || owned.includes(n.id);
          const isLocked = n.price > 0 && !owned.includes(n.id);
          return `
            <div class="wn-item ${isActive ? 'active' : ''} ${isLocked ? 'locked' : ''}"
                 data-wn-id="${n.id}">
              <span class="wn-icon">${n.icon}</span>
              <span class="wn-name">${n.name}</span>
              ${isLocked ? `<span class="wn-price"> ${n.price}</span>` : ''}
              ${isActive && !isMuted ? '<span class="wn-playing">♪</span>' : ''}
            </div>
          `;
        }).join('')}
      </div>
      ${currentId ? `
        <div class="wn-volume-row">
          <span class="wn-vol-icon">🔈</span>
          <input type="range" class="wn-volume-slider" id="wn-volume-slider"
                 min="0" max="1" step="0.01" value="${currentVolume}">
          <span class="wn-vol-icon">🔊</span>
        </div>
      ` : ''}
    </div>
  `;
}

/**
 * 绑定白噪音事件
 */
export function bindWhiteNoiseEvents() {
  // 点击白噪音项
  document.querySelectorAll('.wn-item').forEach(el => {
    el.addEventListener('click', () => {
      const id = el.dataset.wnId;
      if (currentId === id) {
        stopWhiteNoise();
      } else {
        playWhiteNoise(id);
      }
    });
  });

  // 静音按钮
  const muteBtn = document.getElementById('wn-mute-btn');
  if (muteBtn) {
    muteBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      toggleMute();
    });
  }

  // 音量滑块
  const slider = document.getElementById('wn-volume-slider');
  if (slider) {
    slider.addEventListener('input', (e) => {
      setWhiteNoiseVolume(parseFloat(e.target.value));
    });
  }
}

/**
 * 更新白噪音UI（不重新渲染整个面板）
 */
function updateWhiteNoiseUI() {
  const panel = document.querySelector('.white-noise-panel');
  if (!panel) return;

  // 更新active状态
  panel.querySelectorAll('.wn-item').forEach(el => {
    const id = el.dataset.wnId;
    el.classList.toggle('active', id === currentId);
    // 更新播放指示
    const playing = el.querySelector('.wn-playing');
    if (id === currentId && !isMuted) {
      if (!playing) {
        el.insertAdjacentHTML('beforeend', '<span class="wn-playing">♪</span>');
      }
    } else if (playing) {
      playing.remove();
    }
  });

  // 更新静音按钮
  const muteBtn = document.getElementById('wn-mute-btn');
  if (muteBtn) {
    muteBtn.textContent = isMuted ? '🔇' : (currentId ? '🔊' : '🔈');
  }

  // 音量滑块
  const slider = document.getElementById('wn-volume-slider');
  if (slider) {
    slider.value = currentVolume;
  }

  // 如果没有正在播放，移除音量条
  if (!currentId) {
    const volRow = panel.querySelector('.wn-volume-row');
    if (volRow) volRow.remove();
  } else if (!panel.querySelector('.wn-volume-row')) {
    panel.insertAdjacentHTML('beforeend', `
      <div class="wn-volume-row">
        <span class="wn-vol-icon">🔉</span>
        <input type="range" class="wn-volume-slider" id="wn-volume-slider"
               min="0" max="1" step="0.01" value="${currentVolume}">
        <span class="wn-vol-icon">🔊</span>
      </div>
    `);
    document.getElementById('wn-volume-slider').addEventListener('input', (e) => {
      setWhiteNoiseVolume(parseFloat(e.target.value));
    });
  }
}

/**
 * Toast提示
 */
function showToast(msg) {
  const existing = document.querySelector('.wn-toast');
  if (existing) existing.remove();

  const toast = document.createElement('div');
  toast.className = 'wn-toast';
  toast.textContent = msg;
  document.body.appendChild(toast);
  requestAnimationFrame(() => toast.classList.add('show'));
  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 300);
  }, 2000);
}
