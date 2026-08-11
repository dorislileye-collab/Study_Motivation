# AGENTS.md - 学习激励记录仪

## 项目概览

学习激励记录仪 - H5移动端应用，帮助学生记录学习过程、管理任务、培养学习习惯。

## 技术栈

- **类型**: 原生静态H5应用 (native-static)
- **前端**: 原生 HTML5 + CSS3 + ES Modules
- **部署**: 静态文件服务器 (Python http.server / npx serve)
- **构建**: 无构建步骤，纯静态资源

## 目录结构

```
.
├── index.html          # 主入口 (含内联启动屏)
├── style.css           # 全局样式 (~2870行)
├── main.js             # 应用入口 & 路由
├── src/
│   ├── home.js         # 首页 (任务管理)
│   ├── calendar.js     # 日历视图
│   ├── timer.js        # 计时器 (双模式)
│   ├── game.js         # 游戏中心
│   ├── mine.js         # 个人中心
│   ├── store.js        # 商城
│   ├── themes.js       # 主题定义 (12套)
│   ├── theme-manager.js # 主题管理
│   ├── decoration-manager.js # 装饰管理
│   ├── sound.js        # 音效引擎
│   ├── celebration.js  # 庆祝动画
│   └── games/
│       ├── sand.js     # 沙画游戏
│       ├── bubble.js   # 泡泡游戏
│       └── crush.js    # 情绪粉碎机
└── public/             # 静态资源
    ├── avatars/        # 头像
    ├── themes/         # 主题图片
    ├── items/          # 商城物品
    ├── sketches/       # 手绘素材
    ├── achievements/   # 成就图标
    └── games/          # 游戏素材
```

## 核心功能

1. **首页** - 今日任务管理、快捷入口
2. **日历** - 月历视图、日期任务管理
3. **计时** - 专注模式 + 自由模式计时器
4. **游戏** - 沙画/泡泡/情绪粉碎机 (Canvas动画，4种销毁方式)
5. **我的** - 金币、等级、衣柜、成就、主题切换

## 装饰系统

- 装饰管理器根据衣柜装备状态智能放置手绘素材
- 支持：常规定位、浮动动画、视差滚动、蝴蝶飞舞、花瓣飘落、偷看效果
- 每个主题在不同页面有专属装饰（日历/首页/游戏/计时器/我的）

## 开发规范

- 使用 ES Modules (`type="module"`)
- 数据存储: localStorage
- 移动端优先 (max-width: 480px)
- 支持 12 套主题切换
- 支持安全区域适配 (safe-area-inset)

## 启动命令

```bash
# 开发环境
python -m http.server 5000 --bind 0.0.0.0

# 或使用 npx serve
npx serve -l 5000 -s .
```
