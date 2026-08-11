/**
 * 祝贺特效模块 - CSS + Canvas 彩带/星星粒子特效
 */

/**
 * 显示全屏祝贺特效
 * @param {number} duration - 持续时间(ms)，默认 2500
 */
export function showCelebration(duration = 2500) {
  const canvas = document.createElement('canvas');
  canvas.className = 'celebration-canvas';
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  document.body.appendChild(canvas);

  const ctx = canvas.getContext('2d');
  const particles = [];
  const colors = ['#FFD700', '#FF6B6B', '#4ECDC4', '#45B7D1', '#96CEB4', '#FFEAA7', '#DDA0DD', '#98D8C8'];

  // 创建彩带粒子
  for (let i = 0; i < 80; i++) {
    particles.push({
      x: Math.random() * canvas.width,
      y: -20 - Math.random() * 200,
      w: 6 + Math.random() * 8,
      h: 4 + Math.random() * 4,
      color: colors[Math.floor(Math.random() * colors.length)],
      vx: (Math.random() - 0.5) * 4,
      vy: 2 + Math.random() * 4,
      rotation: Math.random() * Math.PI * 2,
      rotationSpeed: (Math.random() - 0.5) * 0.2,
      opacity: 1,
    });
  }

  // 创建星星粒子（从中心爆发）
  const cx = canvas.width / 2;
  const cy = canvas.height / 2;
  for (let i = 0; i < 30; i++) {
    const angle = (Math.PI * 2 / 30) * i;
    const speed = 3 + Math.random() * 5;
    particles.push({
      x: cx,
      y: cy,
      w: 8 + Math.random() * 6,
      h: 8 + Math.random() * 6,
      color: colors[Math.floor(Math.random() * colors.length)],
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      rotation: 0,
      rotationSpeed: (Math.random() - 0.5) * 0.3,
      opacity: 1,
      isStar: true,
      gravity: 0.08,
    });
  }

  let startTime = null;

  function drawStar(ctx, x, y, size, rotation) {
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(rotation);
    ctx.beginPath();
    for (let i = 0; i < 5; i++) {
      const angle = (i * 4 * Math.PI) / 5 - Math.PI / 2;
      const method = i === 0 ? 'moveTo' : 'lineTo';
      ctx[method](Math.cos(angle) * size, Math.sin(angle) * size);
    }
    ctx.closePath();
    ctx.fillStyle = this.color || '#FFD700';
    ctx.fill();
    ctx.restore();
  }

  function animate(timestamp) {
    if (!startTime) startTime = timestamp;
    const elapsed = timestamp - startTime;
    const progress = elapsed / duration;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    particles.forEach(p => {
      p.x += p.vx;
      p.y += p.vy;
      p.rotation += p.rotationSpeed;

      if (p.isStar) {
        p.vy += p.gravity;
        p.opacity = Math.max(0, 1 - progress * 1.5);
      } else {
        if (elapsed > duration * 0.6) {
          p.opacity = Math.max(0, 1 - (elapsed - duration * 0.6) / (duration * 0.4));
        }
      }

      ctx.save();
      ctx.globalAlpha = p.opacity;
      ctx.translate(p.x, p.y);
      ctx.rotate(p.rotation);

      if (p.isStar) {
        ctx.beginPath();
        for (let i = 0; i < 5; i++) {
          const angle = (i * 4 * Math.PI) / 5 - Math.PI / 2;
          const r = i === 0 ? 0 : p.w / 2;
          const method = i === 0 ? 'moveTo' : 'lineTo';
          const outerAngle = ((i - 0.5) * 2 * Math.PI) / 5 - Math.PI / 2;
          if (i === 0) {
            ctx.moveTo(Math.cos(angle) * p.w / 2, Math.sin(angle) * p.w / 2);
          } else {
            ctx.lineTo(Math.cos(angle) * p.w / 2, Math.sin(angle) * p.w / 2);
            ctx.lineTo(Math.cos(outerAngle) * p.w / 4, Math.sin(outerAngle) * p.w / 4);
          }
        }
        ctx.closePath();
        ctx.fillStyle = p.color;
        ctx.fill();
      } else {
        ctx.fillStyle = p.color;
        ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h);
      }

      ctx.restore();
    });

    if (elapsed < duration) {
      requestAnimationFrame(animate);
    } else {
      canvas.remove();
    }
  }

  requestAnimationFrame(animate);
}
