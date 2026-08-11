/**
 * 主题数据模块 - 16个主题，每个主题7个配饰维度
 * 维度: font(全局字体), calendar(日历), task(待办), bg(背景),
 *       quote(激励语句), timer(计时面板), game(游戏面板)
 *
 * 变量约定：
 *   calendar: --calendar-cell-bg / --calendar-cell-border / --calendar-radius / --calendar-dot
 *   task:     --task-bg / --task-border(border-left颜色) / --task-radius / --task-check
 *   timer:    --timer-bg / --timer-border / --timer-number / --timer-shadow(发光等装饰)
 *   game:     --game-bg / --game-border / --game-pattern / --game-pattern-size
 *   bg:       --bg-color / --bg-gradient / --bg-pattern / --text-primary / --text-secondary
 *   quote:    --quote-color / --quote-shadow
 */

/** 7个衣柜维度定义 */
export const WARDROBE_DIMENSIONS = [
  { id: 'font', name: '全局字体', icon: '🔤' },
  { id: 'calendar', name: '日历配饰', icon: '📅' },
  { id: 'task', name: '待办配饰', icon: '📋' },
  { id: 'bg', name: '整体背景', icon: '🎨' },
  { id: 'quote', name: '激励语句', icon: '💬' },
  { id: 'timer', name: '计时面板', icon: '⏱' },
  { id: 'game', name: '游戏面板', icon: '🎮' },
];

/** 等级定义 */
export const TIERS = {
  default: { name: '默认', color: '#8B6914', cssClass: 'theme-tier-default' },
  normal:  { name: '普通', color: '#607D8B', cssClass: 'theme-tier-normal' },
  advanced:{ name: '进阶', color: '#0096B4', cssClass: 'theme-tier-advanced' },
  high:    { name: '高阶', color: '#7B1FA2', cssClass: 'theme-tier-high' },
  top:     { name: '顶级', color: '#E65100', cssClass: 'theme-tier-top' },
  legend:  { name: '传说', color: '#FF006E', cssClass: 'theme-tier-legend' },
};

/** @type {Array} 全部16个主题 */
export const THEMES = [
  // ===== 默认免费 =====
  {
    id: 'wood', name: '米色简约木质风', emoji: '🪵', tier: 'default', btnColor: '#A9885A',
    price: 0, available: true,
    accessories: {
      font:   { fontFamily: "'Segoe UI','PingFang SC','Microsoft YaHei',sans-serif" },
      calendar: { '--calendar-cell-bg': '#FFFDF7', '--calendar-cell-border': '#E0D5C1', '--calendar-radius': '12px', '--calendar-dot': '#C4A66A' },
      task:   { '--task-bg': '#FFFDF7', '--task-border': '#C4A66A', '--task-radius': '10px', '--task-check': '#C4A66A' },
      bg:     { '--bg-color': '#F5F0E8', '--bg-gradient': 'linear-gradient(135deg,#F5F0E8 0%,#EDE4D3 50%,#F5F0E8 100%)', '--bg-pattern': 'repeating-linear-gradient(90deg,transparent,transparent 40px,rgba(139,105,20,0.04) 40px,rgba(139,105,20,0.04) 41px)', '--text-primary': '#5C4A2A', '--text-secondary': '#8B7355', '--card-bg': '#FFFDF7', '--card-border': '#E0D5C1' },
      quote:  { '--quote-color': '#8B6914', '--quote-shadow': 'none' },
      timer:  { '--timer-bg': '#FFFDF7', '--timer-border': '#C4A66A', '--timer-number': '#5C4A2A', '--timer-shadow': '0 4px 20px rgba(139,115,85,0.15), inset 0 0 0 4px rgba(196,166,106,0.08)' },
      game:   { '--game-bg': '#FFF9F0', '--game-border': '#E0D5C1', '--game-pattern': 'none' },
    },
  },
  // ===== 普通 =====
  {
    id: 'sunrise', name: '日出时分', emoji: '🌅', tier: 'normal', btnColor: '#FF7043',
    price: 200, available: true,
    accessories: {
      font:   { fontFamily: "'Nunito','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#FFF3E6', '--calendar-cell-border': '#FFB38A', '--calendar-radius': '16px', '--calendar-dot': '#FF6B35' },
      task:   { '--task-bg': 'linear-gradient(90deg,#FFE4D6,#FFF0E8)', '--task-border': '#FF6B35', '--task-radius': '16px', '--task-check': '#FF6B35' },
      bg:     { '--bg-color': '#FFF0E0', '--bg-gradient': 'linear-gradient(180deg,#FFD4A8 0%,#FFE8CC 40%,#FFF5EA 100%)', '--bg-pattern': 'radial-gradient(circle at 50% 0%,rgba(255,107,53,0.18) 0%,transparent 45%)', '--text-primary': '#7A3B1E', '--text-secondary': '#B06A45', '--card-bg': '#FFF8F0', '--card-border': '#FFD4B8' },
      quote:  { '--quote-color': '#FF6B35', '--quote-shadow': '0 1px 6px rgba(255,107,53,0.3)' },
      timer:  { '--timer-bg': '#FFF3E6', '--timer-border': '#FF6B35', '--timer-number': '#E5522A', '--timer-shadow': '0 6px 24px rgba(255,107,53,0.25)' },
      game:   { '--game-bg': '#FFF0E0', '--game-border': '#FFB38A', '--game-pattern': 'radial-gradient(circle at 50% 100%,rgba(255,107,53,0.1) 0%,transparent 50%)' },
    },
  },
  {
    id: 'kgray', name: '韩系简约灰', emoji: '🩶', tier: 'normal', btnColor: '#757575',
    price: 200, available: true,
    accessories: {
      font:   { fontFamily: "'Noto Sans KR','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#F7F7F7', '--calendar-cell-border': '#DDDDDD', '--calendar-radius': '4px', '--calendar-dot': '#555555' },
      task:   { '--task-bg': '#FAFAFA', '--task-border': '#9E9E9E', '--task-radius': '4px', '--task-check': '#555555' },
      bg:     { '--bg-color': '#EFEFEF', '--bg-gradient': 'linear-gradient(160deg,#F5F5F5 0%,#E8E8E8 100%)', '--bg-pattern': 'none', '--text-primary': '#333333', '--text-secondary': '#757575', '--card-bg': '#FFFFFF', '--card-border': '#E0E0E0' },
      quote:  { '--quote-color': '#424242', '--quote-shadow': 'none' },
      timer:  { '--timer-bg': '#FFFFFF', '--timer-border': '#BDBDBD', '--timer-number': '#212121', '--timer-shadow': '0 2px 12px rgba(0,0,0,0.06)' },
      game:   { '--game-bg': '#F5F5F5', '--game-border': '#DDDDDD', '--game-pattern': 'none' },
    },
  },
  {
    id: 'springgreen', name: '春日粉绿', emoji: '🌿', tier: 'normal', btnColor: '#66BB6A',
    price: 200, available: true,
    accessories: {
      font:   { fontFamily: "'Quicksand','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#EAF7EC', '--calendar-cell-border': '#A5D6A7', '--calendar-radius': '50%', '--calendar-dot': '#43A047' },
      task:   { '--task-bg': 'linear-gradient(90deg,#F1F8F2,#FDF5F7)', '--task-border': '#66BB6A', '--task-radius': '20px', '--task-check': '#66BB6A' },
      bg:     { '--bg-color': '#F0FAF0', '--bg-gradient': 'linear-gradient(135deg,#E0F2E9 0%,#FFF0F5 55%,#F0FFF4 100%)', '--bg-pattern': 'radial-gradient(circle at 15% 85%,rgba(102,187,106,0.12) 0%,transparent 40%),radial-gradient(circle at 85% 15%,rgba(244,143,177,0.10) 0%,transparent 40%)', '--text-primary': '#2E5B3F', '--text-secondary': '#6B9080', '--card-bg': '#FBFFFB', '--card-border': '#C8E6C9' },
      quote:  { '--quote-color': '#43A047', '--quote-shadow': '0 1px 5px rgba(67,160,71,0.25)' },
      timer:  { '--timer-bg': '#F1FBF3', '--timer-border': '#66BB6A', '--timer-number': '#2E7D32', '--timer-shadow': '0 6px 22px rgba(102,187,106,0.25)' },
      game:   { '--game-bg': '#F4FBF4', '--game-border': '#A5D6A7', '--game-pattern': 'radial-gradient(circle at 20% 20%,rgba(244,143,177,0.08) 0%,transparent 35%)' },
    },
  },
  {
    id: 'minimal', name: '极简灰白', emoji: '⬜', tier: 'normal', btnColor: '#424242',
    price: 200, available: true,
    accessories: {
      font:   { fontFamily: "'Inter','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#FFFFFF', '--calendar-cell-border': '#F0F0F0', '--calendar-radius': '0px', '--calendar-dot': '#111111' },
      task:   { '--task-bg': '#FFFFFF', '--task-border': '#111111', '--task-radius': '0px', '--task-check': '#111111' },
      bg:     { '--bg-color': '#FFFFFF', '--bg-gradient': 'linear-gradient(180deg,#FFFFFF 0%,#FCFCFC 100%)', '--bg-pattern': 'none', '--text-primary': '#111111', '--text-secondary': '#888888', '--card-bg': '#FFFFFF', '--card-border': '#ECECEC' },
      quote:  { '--quote-color': '#111111', '--quote-shadow': 'none' },
      timer:  { '--timer-bg': '#FFFFFF', '--timer-border': '#111111', '--timer-number': '#111111', '--timer-shadow': '8px 8px 0 rgba(17,17,17,0.08)' },
      game:   { '--game-bg': '#FFFFFF', '--game-border': '#E5E5E5', '--game-pattern': 'none' },
    },
  },
  // ===== 进阶 =====
  {
    id: 'pixel', name: '像素疯狂', emoji: '👾', tier: 'advanced', btnColor: '#E65100',
    price: 400, available: true,
    accessories: {
      font:   { fontFamily: "'Press Start 2P','Courier New',monospace" },
      calendar: { '--calendar-cell-bg': '#16213E', '--calendar-cell-border': '#00FF41', '--calendar-radius': '0px', '--calendar-dot': '#FFD700' },
      task:   { '--task-bg': '#16213E', '--task-border': '#00FF41', '--task-radius': '0px', '--task-check': '#00FF41' },
      bg:     { '--bg-color': '#0F0F23', '--bg-gradient': 'linear-gradient(135deg,#0F0F23 0%,#1A1A3E 50%,#0F2027 100%)', '--bg-pattern': 'linear-gradient(0deg,rgba(0,255,65,0.05) 1px,transparent 1px),linear-gradient(90deg,rgba(0,255,65,0.05) 1px,transparent 1px)', '--bg-pattern-size': '20px 20px', '--text-primary': '#E0FFE8', '--text-secondary': '#7FBC8C', '--card-bg': '#16213E', '--card-border': '#0F3460' },
      quote:  { '--quote-color': '#FFD700', '--quote-shadow': '2px 2px 0 rgba(255,0,110,0.6)' },
      timer:  { '--timer-bg': '#16213E', '--timer-border': '#00FF41', '--timer-number': '#00FF41', '--timer-shadow': '0 0 16px rgba(0,255,65,0.35), inset 0 0 12px rgba(0,255,65,0.1)' },
      game:   { '--game-bg': '#0F0F23', '--game-border': '#00FF41', '--game-pattern': 'linear-gradient(0deg,rgba(255,215,0,0.04) 2px,transparent 2px),linear-gradient(90deg,rgba(255,215,0,0.04) 2px,transparent 2px)', '--game-pattern-size': '16px 16px' },
    },
  },
  {
    id: 'cat', name: '浅黄萌猫咪', emoji: '🐱', tier: 'advanced', btnColor: '#FFA000',
    price: 400, available: true,
    accessories: {
      font:   { fontFamily: "'Comic Sans MS','Nunito','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#FFF6C9', '--calendar-cell-border': '#FFC93C', '--calendar-radius': '22px', '--calendar-dot': '#FF9800', decorationImage: 'public/sketches/cat-paw.jpeg' },
      task:   { '--task-bg': 'linear-gradient(90deg,#FFF6C9,#FFFBE6)', '--task-border': '#FFC93C', '--task-radius': '22px', '--task-check': '#FF9800', decorationImage: 'public/sketches/cat-head.jpeg' },
      bg:     { '--bg-color': '#FFF9D6', '--bg-gradient': 'linear-gradient(135deg,#FFF3B0 0%,#FFF9D6 50%,#FFE98A 100%)', '--bg-pattern': 'radial-gradient(circle at 12% 20%,rgba(255,152,0,0.12) 0%,transparent 25%),radial-gradient(circle at 88% 75%,rgba(255,201,60,0.16) 0%,transparent 28%)', '--text-primary': '#7A5200', '--text-secondary': '#B08A2E', '--card-bg': '#FFFBE6', '--card-border': '#FFD95A' },
      quote:  { '--quote-color': '#FF8C00', '--quote-shadow': '0 2px 6px rgba(255,140,0,0.3)' },
      timer:  { '--timer-bg': '#FFF6C9', '--timer-border': '#FFC93C', '--timer-number': '#E68A00', '--timer-shadow': '0 6px 24px rgba(255,201,60,0.4)' },
      game:   { '--game-bg': '#FFF9D6', '--game-border': '#FFC93C', '--game-pattern': 'radial-gradient(circle at 30% 30%,rgba(255,152,0,0.08) 0%,transparent 30%)' },
    },
  },
  {
    id: 'beach', name: '夏日海滩', emoji: '🏖️', tier: 'advanced', btnColor: '#0096C7',
    price: 400, available: true,
    accessories: {
      font:   { fontFamily: "'Caveat','PingFang SC',cursive" },
      calendar: { '--calendar-cell-bg': '#E3F4FC', '--calendar-cell-border': '#4FC3F7', '--calendar-radius': '14px', '--calendar-dot': '#006994', decorationImage: 'public/sketches/palm-leaf.jpeg' },
      task:   { '--task-bg': 'linear-gradient(90deg,#E3F4FC,#FDF6E3)', '--task-border': '#0096C7', '--task-radius': '14px', '--task-check': '#006994', decorationImage: 'public/sketches/seashell.jpeg' },
      bg:     { '--bg-color': '#DDF2FC', '--bg-gradient': 'linear-gradient(180deg,#7FD4F5 0%,#C8EAF7 45%,#FCEBB6 100%)', '--bg-pattern': 'radial-gradient(ellipse at 50% 100%,rgba(0,105,148,0.12) 0%,transparent 55%)', '--text-primary': '#075A7A', '--text-secondary': '#3E8EAD', '--card-bg': '#F0FAFF', '--card-border': '#8ED8F0' },
      quote:  { '--quote-color': '#006994', '--quote-shadow': '0 1px 6px rgba(0,150,199,0.3)' },
      timer:  { '--timer-bg': '#E3F4FC', '--timer-border': '#0096C7', '--timer-number': '#005F8A', '--timer-shadow': '0 6px 22px rgba(0,150,199,0.28)' },
      game:   { '--game-bg': '#E8F6FD', '--game-border': '#4FC3F7', '--game-pattern': 'radial-gradient(ellipse at 50% 100%,rgba(252,235,182,0.5) 0%,transparent 40%)' },
    },
  },
  // ===== 高阶 =====
  {
    id: 'punk', name: '甜酷朋克', emoji: '🎸', tier: 'high', btnColor: '#FF2E93',
    price: 700, available: true,
    accessories: {
      font:   { fontFamily: "'Permanent Marker','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#2D1B4E', '--calendar-cell-border': '#FF2E93', '--calendar-radius': '10px', '--calendar-dot': '#00E5FF' },
      task:   { '--task-bg': '#2D1B4E', '--task-border': '#FF2E93', '--task-radius': '10px', '--task-check': '#00E5FF' },
      bg:     { '--bg-color': '#1A0B2E', '--bg-gradient': 'linear-gradient(135deg,#1A0B2E 0%,#3D1A5C 50%,#120821 100%)', '--bg-pattern': 'radial-gradient(circle at 25% 25%,rgba(255,46,147,0.12) 0%,transparent 35%),radial-gradient(circle at 75% 75%,rgba(0,229,255,0.10) 0%,transparent 35%)', '--text-primary': '#FFE3F2', '--text-secondary': '#C792EA', '--card-bg': '#251242', '--card-border': '#5C2E8C' },
      quote:  { '--quote-color': '#FF2E93', '--quote-shadow': '0 0 10px rgba(255,46,147,0.6), 0 0 20px rgba(0,229,255,0.3)' },
      timer:  { '--timer-bg': '#251242', '--timer-border': '#FF2E93', '--timer-number': '#00E5FF', '--timer-shadow': '0 0 18px rgba(255,46,147,0.5), 0 0 36px rgba(0,229,255,0.25)' },
      game:   { '--game-bg': '#1A0B2E', '--game-border': '#FF2E93', '--game-pattern': 'linear-gradient(45deg,rgba(255,46,147,0.05) 25%,transparent 25%,transparent 75%,rgba(0,229,255,0.05) 75%)', '--game-pattern-size': '28px 28px' },
    },
  },
  {
    id: 'gothic', name: '暗黑哥特', emoji: '🦇', tier: 'high', btnColor: '#8B0000',
    price: 700, available: true,
    accessories: {
      font:   { fontFamily: "'Georgia','Times New Roman',serif" },
      calendar: { '--calendar-cell-bg': '#170A1E', '--calendar-cell-border': '#8B0000', '--calendar-radius': '2px', '--calendar-dot': '#B22222' },
      task:   { '--task-bg': '#1C0D24', '--task-border': '#8B0000', '--task-radius': '2px', '--task-check': '#B22222' },
      bg:     { '--bg-color': '#0D0512', '--bg-gradient': 'linear-gradient(180deg,#0D0512 0%,#1E0A26 60%,#0D0512 100%)', '--bg-pattern': 'radial-gradient(ellipse at 50% 0%,rgba(178,34,34,0.10) 0%,transparent 50%)', '--text-primary': '#D8C8E0', '--text-secondary': '#8A7496', '--card-bg': '#170A1E', '--card-border': '#3D1A4E' },
      quote:  { '--quote-color': '#C41E3A', '--quote-shadow': '0 0 12px rgba(196,30,58,0.5)' },
      timer:  { '--timer-bg': '#170A1E', '--timer-border': '#8B0000', '--timer-number': '#FF3355', '--timer-shadow': '0 0 20px rgba(139,0,0,0.6), inset 0 0 16px rgba(139,0,0,0.2)' },
      game:   { '--game-bg': '#0F0616', '--game-border': '#4A1040', '--game-pattern': 'repeating-linear-gradient(45deg,transparent,transparent 14px,rgba(139,0,0,0.05) 14px,rgba(139,0,0,0.05) 15px)' },
    },
  },
  {
    id: 'bear', name: '浅卡其玩偶熊', emoji: '🧸', tier: 'high', btnColor: '#8B5A2B',
    price: 700, available: true,
    accessories: {
      font:   { fontFamily: "'KaiTi','STKaiti','PingFang SC',serif" },
      calendar: { '--calendar-cell-bg': '#F0DCC0', '--calendar-cell-border': '#8B5A2B', '--calendar-radius': '12px', '--calendar-dot': '#6B4423', decorationImage: 'public/sketches/bear-paw.jpeg' },
      task:   { '--task-bg': 'linear-gradient(90deg,#F0DCC0,#F7E9D4)', '--task-border': '#8B5A2B', '--task-radius': '12px', '--task-check': '#6B4423', decorationImage: 'public/sketches/bear-head.jpeg' },
      bg:     { '--bg-color': '#E9D2B4', '--bg-gradient': 'linear-gradient(135deg,#DFC49F 0%,#EFDCC2 50%,#D4B48C 100%)', '--bg-pattern': 'repeating-linear-gradient(90deg,transparent,transparent 26px,rgba(107,68,35,0.06) 26px,rgba(107,68,35,0.06) 28px)', '--text-primary': '#4A2F17', '--text-secondary': '#7D5A38', '--card-bg': '#F5E6CF', '--card-border': '#B98E5F' },
      quote:  { '--quote-color': '#6B4423', '--quote-shadow': '0 1px 4px rgba(107,68,35,0.25)' },
      timer:  { '--timer-bg': '#F0DCC0', '--timer-border': '#8B5A2B', '--timer-number': '#4A2F17', '--timer-shadow': '0 6px 20px rgba(139,90,43,0.3), inset 0 0 0 6px rgba(139,90,43,0.08)' },
      game:   { '--game-bg': '#EDD8BC', '--game-border': '#B98E5F', '--game-pattern': 'repeating-linear-gradient(0deg,transparent,transparent 20px,rgba(107,68,35,0.05) 20px,rgba(107,68,35,0.05) 22px)' },
    },
  },
  // ===== 顶级 =====
  {
    id: 'matrix', name: '数据矩阵', emoji: '💻', tier: 'top', btnColor: '#00A550',
    price: 1200, available: true,
    accessories: {
      font:   { fontFamily: "'Courier New','Consolas',monospace" },
      calendar: { '--calendar-cell-bg': '#050F05', '--calendar-cell-border': '#00FF41', '--calendar-radius': '0px', '--calendar-dot': '#00FF41' },
      task:   { '--task-bg': '#071207', '--task-border': '#00FF41', '--task-radius': '0px', '--task-check': '#00FF41' },
      bg:     { '--bg-color': '#000000', '--bg-gradient': 'linear-gradient(135deg,#000000 0%,#041004 50%,#000500 100%)', '--bg-pattern': 'linear-gradient(0deg,rgba(0,255,65,0.06) 1px,transparent 1px)', '--bg-pattern-size': '24px 24px', '--text-primary': '#B8FFC4', '--text-secondary': '#4E9A5E', '--card-bg': '#050F05', '--card-border': '#0A4D1C' },
      quote:  { '--quote-color': '#00FF41', '--quote-shadow': '0 0 10px rgba(0,255,65,0.7)' },
      timer:  { '--timer-bg': '#050F05', '--timer-border': '#00FF41', '--timer-number': '#00FF41', '--timer-shadow': '0 0 20px rgba(0,255,65,0.4), inset 0 0 14px rgba(0,255,65,0.12)' },
      game:   { '--game-bg': '#020802', '--game-border': '#0A4D1C', '--game-pattern': 'linear-gradient(0deg,rgba(0,255,65,0.05) 1px,transparent 1px),linear-gradient(90deg,rgba(0,255,65,0.05) 1px,transparent 1px)', '--game-pattern-size': '30px 30px' },
    },
  },
  {
    id: 'doomsday', name: '末日世界', emoji: '☢️', tier: 'top', btnColor: '#B7410E',
    price: 1200, available: true,
    accessories: {
      font:   { fontFamily: "'Impact','Arial Black',sans-serif" },
      calendar: { '--calendar-cell-bg': '#2A2520', '--calendar-cell-border': '#B7410E', '--calendar-radius': '3px', '--calendar-dot': '#FF6B1A' },
      task:   { '--task-bg': '#252018', '--task-border': '#B7410E', '--task-radius': '3px', '--task-check': '#FF6B1A' },
      bg:     { '--bg-color': '#171410', '--bg-gradient': 'linear-gradient(135deg,#171410 0%,#2A2520 50%,#141210 100%)', '--bg-pattern': 'repeating-linear-gradient(45deg,transparent,transparent 10px,rgba(183,65,14,0.06) 10px,rgba(183,65,14,0.06) 11px)', '--text-primary': '#E0CBA8', '--text-secondary': '#9A8265', '--card-bg': '#221D17', '--card-border': '#5A4632' },
      quote:  { '--quote-color': '#FF6B1A', '--quote-shadow': '0 0 8px rgba(255,107,26,0.5)' },
      timer:  { '--timer-bg': '#2A2520', '--timer-border': '#B7410E', '--timer-number': '#FF4444', '--timer-shadow': '0 0 18px rgba(183,65,14,0.45), inset 0 0 12px rgba(0,0,0,0.5)' },
      game:   { '--game-bg': '#1A1510', '--game-border': '#6B4226', '--game-pattern': 'repeating-linear-gradient(0deg,transparent,transparent 8px,rgba(107,66,38,0.10) 8px,rgba(107,66,38,0.10) 9px)' },
    },
  },
  {
    id: 'deepsea', name: '深海之息', emoji: '🌊', tier: 'top', btnColor: '#0077B6',
    price: 1200, available: true,
    accessories: {
      font:   { fontFamily: "'Quicksand','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': 'rgba(0,50,95,0.75)', '--calendar-cell-border': '#1A6B8A', '--calendar-radius': '14px', '--calendar-dot': '#7FDBDA', decorationImage: 'public/sketches/jellyfish.jpeg' },
      task:   { '--task-bg': 'rgba(0,60,110,0.55)', '--task-border': '#00B4D8', '--task-radius': '14px', '--task-check': '#7FDBDA', decorationImage: 'public/sketches/seashell.jpeg' },
      bg:     { '--bg-color': '#061A30', '--bg-gradient': 'linear-gradient(180deg,#020E1D 0%,#0A2A4A 55%,#062038 100%)', '--bg-pattern': 'radial-gradient(ellipse at 30% 80%,rgba(0,180,216,0.10) 0%,transparent 45%),radial-gradient(ellipse at 70% 20%,rgba(127,219,218,0.08) 0%,transparent 45%)', '--text-primary': '#D2F1F4', '--text-secondary': '#7AAFC0', '--card-bg': 'rgba(4,34,62,0.85)', '--card-border': '#14506B' },
      quote:  { '--quote-color': '#7FDBDA', '--quote-shadow': '0 0 12px rgba(127,219,218,0.5)' },
      timer:  { '--timer-bg': 'rgba(4,30,56,0.9)', '--timer-border': '#00B4D8', '--timer-number': '#00FFFF', '--timer-shadow': '0 0 22px rgba(0,180,216,0.4), inset 0 0 16px rgba(0,180,216,0.12)' },
      game:   { '--game-bg': '#052038', '--game-border': '#1A6B8A', '--game-pattern': 'radial-gradient(ellipse at 50% 100%,rgba(0,200,150,0.08) 0%,transparent 60%)' },
    },
  },
  // ===== 传说 =====
  {
    id: 'cyber', name: '霓虹赛博', emoji: '🌆', tier: 'legend', btnColor: '#8A2BE2',
    price: 2000, available: true,
    accessories: {
      font:   { fontFamily: "'Orbitron','Courier New',monospace" },
      calendar: { '--calendar-cell-bg': '#12122E', '--calendar-cell-border': '#00D4FF', '--calendar-radius': '6px', '--calendar-dot': '#FF006E', decorationImage: 'public/sketches/city-skyline.jpeg' },
      task:   { '--task-bg': '#14143A', '--task-border': '#00D4FF', '--task-radius': '6px', '--task-check': '#FF006E' },
      bg:     { '--bg-color': '#08081A', '--bg-gradient': 'linear-gradient(135deg,#08081A 0%,#1C0A38 50%,#0A1B30 100%)', '--bg-pattern': 'linear-gradient(0deg,rgba(0,212,255,0.06) 1px,transparent 1px),linear-gradient(90deg,rgba(255,0,110,0.05) 1px,transparent 1px)', '--bg-pattern-size': '30px 30px', '--text-primary': '#E0F7FF', '--text-secondary': '#7C93B8', '--card-bg': '#101030', '--card-border': '#2A2A5A' },
      quote:  { '--quote-color': '#00FF88', '--quote-shadow': '0 0 8px rgba(0,255,136,0.7), 0 0 20px rgba(0,212,255,0.4)' },
      timer:  { '--timer-bg': '#12122A', '--timer-border': '#00D4FF', '--timer-number': '#00FF88', '--timer-shadow': '0 0 12px rgba(0,212,255,0.6), 0 0 30px rgba(255,0,110,0.3), inset 0 0 14px rgba(0,212,255,0.1)' },
      game:   { '--game-bg': '#0D0D20', '--game-border': '#FF006E', '--game-pattern': 'linear-gradient(0deg,rgba(255,0,110,0.05) 1px,transparent 1px),linear-gradient(90deg,rgba(0,212,255,0.05) 1px,transparent 1px)', '--game-pattern-size': '25px 25px' },
    },
  },
  {
    id: 'sakura', name: '日系樱花粉', emoji: '🌸', tier: 'legend', btnColor: '#EC6A9C',
    price: 2000, available: true,
    accessories: {
      font:   { fontFamily: "'Yu Gothic','Nunito','PingFang SC',sans-serif" },
      calendar: { '--calendar-cell-bg': '#FFF0F5', '--calendar-cell-border': '#F48FB1', '--calendar-radius': '50%', '--calendar-dot': '#EC407A', decorationImage: 'public/sketches/cherry-blossom.jpeg' },
      task:   { '--task-bg': 'linear-gradient(90deg,#FFE9F1,#FFF6F9)', '--task-border': '#F06292', '--task-radius': '18px', '--task-check': '#EC407A', decorationImage: 'public/sketches/butterfly.jpeg' },
      bg:     { '--bg-color': '#FFF2F6', '--bg-gradient': 'linear-gradient(135deg,#FFE4EE 0%,#FFF0F5 50%,#FDE3EC 100%)', '--bg-pattern': 'radial-gradient(circle at 10% 15%,rgba(244,143,177,0.16) 0%,transparent 30%),radial-gradient(circle at 90% 80%,rgba(236,64,122,0.10) 0%,transparent 32%)', '--text-primary': '#8C4A62', '--text-secondary': '#C08497', '--card-bg': '#FFFAFC', '--card-border': '#F5C6D6' },
      quote:  { '--quote-color': '#EC407A', '--quote-shadow': '0 1px 8px rgba(236,64,122,0.3)' },
      timer:  { '--timer-bg': '#FFF5F8', '--timer-border': '#F48FB1', '--timer-number': '#C2185B', '--timer-shadow': '0 8px 26px rgba(244,143,177,0.4)' },
      game:   { '--game-bg': '#FFF5F8', '--game-border': '#F5C6D6', '--game-pattern': 'radial-gradient(circle at 15% 15%,rgba(244,143,177,0.12) 0%,transparent 25%),radial-gradient(circle at 85% 85%,rgba(244,143,177,0.12) 0%,transparent 25%)' },
    },
  },
];

/** 根据ID查找主题 */
export function getThemeById(id) {
  return THEMES.find(t => t.id === id) || THEMES[0];
}

/** 获取某个维度的所有可用配饰（来自所有主题） */
export function getAccessoriesByDimension(dimId) {
  const result = [];
  THEMES.forEach(theme => {
    if (theme.accessories[dimId]) {
      result.push({
        themeId: theme.id,
        themeName: theme.name,
        themeEmoji: theme.emoji,
        tier: theme.tier,
        dimId,
        styles: theme.accessories[dimId],
      });
    }
  });
  return result;
}

/** 计算整主题价格（比单买便宜15%） */
export function calcThemeBundlePrice(theme) {
  const dimCount = Object.keys(theme.accessories).length;
  const tierPrices = { default: 0, normal: 50, advanced: 80, high: 120, top: 170, legend: 250 };
  const singlePrice = tierPrices[theme.tier] || 50;
  const totalSingle = dimCount * singlePrice;
  return Math.floor(totalSingle * 0.85);
}

/** 获取某个主题的某个维度的装饰图片路径 */
export function getDecorationImage(themeId, dimId) {
  const theme = getThemeById(themeId);
  return theme.accessories[dimId]?.decorationImage || null;
}
