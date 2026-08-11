# StudyMotivator (iOS)

H5 应用「学习激励记录仪」(`../learning-recorder/`) 的 SwiftUI 原生重写版。

## 运行

1. 用 Xcode 打开 `StudyMotivator.xcodeproj`
2. 在 Signing & Capabilities 里选择你的 Development Team（Bundle ID: `com.studymotivator.app`，可自行修改）
3. 选择 iPhone 模拟器或真机，Cmd+R 运行

要求：Xcode 16+（工程使用同步文件夹格式，新增 .swift 文件到 `StudyMotivator/` 目录会自动加入编译，无需手动加文件）。iOS 部署目标 17.0，仅竖屏。

## 架构

```
StudyMotivator/
├── StudyMotivatorApp.swift   # @main 入口，启动时 recordActive 打卡
├── ContentView.swift         # 底部 5 Tab（首页/日历/计时/游戏/我的）
├── Models/Models.swift       # StudyTask / AppState / DateHelper / TimeFormatter
├── Services/
│   ├── AppStore.swift        # 数据层（UserDefaults 持久化），对应 H5 store.js
│   └── SoundService.swift    # 音效，对应 H5 sound.js
├── Theme/
│   ├── ThemeData.swift       # 16 套主题数据，逐条翻译自 themes.js
│   ├── ThemeManager.swift    # 主题/衣柜/购买/装备，对应 theme-manager.js
│   ├── ThemeModels.swift     # 主题样式模型（颜色为 CSS 字符串）
│   ├── Color+CSS.swift       # Color(css:) 解析 #hex / rgb() / rgba()
│   └── DecorationManager.swift # 装饰规则，对应 decoration-manager.js
├── Views/
│   ├── Home/                 # 首页：任务管理 + 激励语句 + 快捷入口
│   ├── Calendar/             # 日历：月历 + 日期任务 + 学习心得
│   ├── Timer/                # 计时：双模式计时 + 白噪音 + 庆祝动画
│   ├── Game/                 # 游戏中心：时间限制 + 入口
│   ├── Games/                # 沙画 / 泡泡 / 情绪粉碎机（SwiftUI Canvas）
│   ├── Mine/                 # 我的：统计 + 成就 + 衣柜 + 主题商城
│   └── Components/           # ThemedBackground / ThemedCard / 装饰层
└── Resources/
    ├── Sketches/             # 14 张手绘装饰图（bundle 根，UIImage(named:) 加载）
    └── Audio/                # rain / clock / snow-mountain 白噪音 mp3
```

## 数据兼容性

- 数据存储 key 与 H5 一致（`study_motivator_data` 等），但格式为 Codable JSON，与 H5 的 localStorage JSON 不互通（两端独立存储）。
- 所有业务规则（金币奖励、每日 50 金币 buffer、游戏时间每日 1200 秒上限、连续打卡、主题/配饰定价）均照搬 H5。

## 已知简化（相对 H5）

- Web 字体未打包，用系统字体族（rounded/serif/monospaced 等）近似；如需精确还原可下载 Google Fonts ttf 加入 bundle 并在 Info.plist 注册。
- CSS pattern 纹理未还原；发光效果用 `.shadow` 近似。
- 装饰视差滚动（parallax）未实现；其余浮动/飘落/蝴蝶/蝙蝠等动画已实现。
- 个人中心等级规则为新增（H5 无此系统）：每累计学习 2 小时升 1 级。

详见 `CONTRACT.md`（模块间契约文档）。
