# 📚 词根词缀记忆工坊

像搭积木一样记单词 · 掌握 300 个词根，解锁 30,000+ 个英语单词

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🚀 一键部署

[![Deploy with Vercel](https://vercel.com/button)](https://vercel.com/new/clone?repository-url=https://github.com/joeseesun/word-root-workshop)
[![Deploy to Netlify](https://www.netlify.com/img/deploy/button.svg)](https://app.netlify.com/start/deploy?repository=https://github.com/joeseesun/word-root-workshop)
[![Deploy to GitHub Pages](https://img.shields.io/badge/Deploy%20to-GitHub%20Pages-181717?style=flat&logo=github)](https://github.com/joeseesun/word-root-workshop/settings/pages)

## 🎯 项目简介

**词根词缀记忆工坊** 是一个基于科学记忆法的英语词汇学习应用。通过拆解单词的词根、前缀和后缀，帮助你像搭积木一样理解和记忆英语单词。

### ✨ 核心特色

- 🔍 **词根拆解** - 像拆解乐高一样，把复杂单词拆成词根、前缀、后缀
- 🧩 **系统学习** - 300 个核心词根，建立单词家族的记忆网络
- 🎴 **闪卡复习** - 快速翻转卡片，随时随地巩固记忆
- 💾 **无需登录** - 数据保存在本地，隐私安全
- ☁️ **轻量云同步** - 可选开启，用同步码在多设备同步进度
- 📱 **响应式设计** - 完美支持手机、平板、电脑

### 🎨 设计风格

采用 **极简主义（Minimalism）** 设计风格：
- Less is More，去除一切多余元素
- 清晰的视觉层级，专注内容本身
- 柔和的配色，减少视觉疲劳
- 流畅的动效，提升使用体验

## 🚀 快速开始

### 在线访问

直接访问：[https://你的域名.com](https://你的域名.com)

### 本地运行

```bash
# 克隆项目
git clone https://github.com/joeseesun/word-root-workshop.git

# 进入项目目录
cd word-root-workshop/web

# 使用任意 HTTP 服务器运行
# 方式1: Python
python3 -m http.server 8000

# 方式2: Node.js
npx http-server -p 8000

# 方式3: VS Code Live Server 插件
# 右键 index.html -> Open with Live Server
```

然后在浏览器访问：http://localhost:8000

## 📖 功能说明

### 1️⃣ 学习模式

- 系统化学习 300 个核心词根词缀
- 每个词根包含详细解释和例词
- 即时测试，巩固记忆
- 自动保存学习进度

### 2️⃣ 闪卡模式

- 快速翻转卡片复习
- 左右切换词根
- 键盘快捷键支持（← → 空格）
- 实时显示掌握进度

### 3️⃣ 词根索引

- 快速查找任意词根
- 按来源分类筛选
- 查看掌握状态
- 点击查看详细解析

### 4️⃣ 进度管理

- 可视化学习进度
- 成就系统激励
- 数据本地存储（LocalStorage）
- 可选云端同步（Vercel KV）
- 学习历史记录

## 🛠️ 技术栈

- **前端框架**: 无框架，纯原生 HTML/CSS/JavaScript
- **样式**: 极简主义设计系统（minimal.css）
- **字体**: Google Fonts (Inter)
- **存储**: LocalStorage + 可选 Vercel KV 云同步
- **部署**: 静态托管（Vercel / Netlify / GitHub Pages，推荐 Vercel 以启用云同步）

## 📁 项目结构

```text
web/
├── index.html              # 首页
├── learn.html              # 学习模式
├── flashcard.html          # 闪卡模式
├── roots.html              # 词根索引
├── root-detail.html        # 词根详情
├── progress.html           # 学习进度
├── css/
│   └── minimal.css         # 极简主义样式系统
├── js/
│   ├── storage.js          # 本地存储 + 云同步逻辑
│   └── wordData.js         # 300 个词根数据库
├── api/
│   └── sync.js             # 云同步接口（Vercel Function）
├── vercel.json             # Vercel 部署配置
└── README.md               # Web 项目说明
```

## 🎓 词根数据库

当前收录 10 个核心词根（示例）：

| 词根 | 含义 | 例词 |
|------|------|------|
| spect | 看 | inspect, respect, spectator |
| port | 拿、带 | transport, export, import |
| dict | 说 | dictionary, predict, contradict |
| scrib/script | 写 | describe, subscribe, manuscript |
| vis/vid | 看见 | visible, television, video |
| aud | 听 | audio, audience, auditorium |
| graph | 写、画 | photograph, autograph, biography |
| bio | 生命 | biology, biography, antibiotic |
| tele | 远 | telephone, television, telescope |
| phon | 声音 | telephone, microphone, symphony |

> 完整版将包含 300+ 词根，可扩展到 30,000+ 单词

## 🔧 自定义扩展

### 添加新词根

编辑 `js/wordData.js`，按以下格式添加：

```javascript
{
  id: 11,
  root: 'your-root',
  origin: 'Latin',
  meaning: '中文含义',
  meaningEn: 'English meaning',
  description: '词根详细解释',
  examples: [
    {
      word: 'example',
      breakdown: { prefix: 'ex', root: 'ample', suffix: '' },
      meaning: '例子',
      explanation: 'ex (向外) + ample = ...'
    }
  ],
  quiz: {
    question: '测试题目',
    options: ['选项1', '选项2', '选项3', '选项4'],
    correctAnswer: 0
  }
}
```

### 修改设计风格

编辑 `css/minimal.css`，调整颜色和效果：

```css
:root {
  /* 主色调 */
  --color-accent: #FBBF24;          /* 强调色（黄色） */
  --color-text: #0F172A;            /* 主文字 */
  --color-text-secondary: #64748B;  /* 次要文字 */
  --color-border: #E2E8F0;          /* 边框 */
  --color-bg: #FFFFFF;              /* 背景 */

  /* 间距系统（8px 网格） */
  --space-md: 16px;
  --space-lg: 24px;

  /* 圆角 */
  --radius: 8px;
}
```

## 📊 进度数据结构

LocalStorage 存储格式：

```json
{
  "wordRootProgress": {
    "level": 1,
    "masteredRoots": [1, 2, 3],
    "currentRootIndex": 3,
    "totalScore": 30,
    "lastStudyDate": "2024-01-01T00:00:00.000Z",
    "studyStreak": 7,
    "sessionCount": 10,
    "updatedAt": "2024-01-01T00:00:00.000Z"
  },
  "wordRootAchievements": [
    {
      "id": "first_root",
      "type": "milestone",
      "title": "初出茅庐",
      "description": "掌握第一个词根",
      "icon": "🌱",
      "unlockedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "wordRootMeta": {
    "lastModified": "2024-01-01T00:00:00.000Z",
    "lastSyncedAt": "2024-01-01T00:00:00.000Z"
  },
  "wordRootSyncConfig": {
    "syncCode": "WR-ABCD1234"
  }
}
```

## ☁️ 轻量云同步（可选）

云同步默认关闭，不影响离线使用。开启后可以用“同步码”在多设备间同步学习数据。

### 1. 在进度页开启

1. 进入 `progress.html`
2. 在“云端同步（轻量）”输入或生成同步码
3. 点击“保存同步码”
4. 使用“智能同步 / 上传 / 下载”

### 2. 服务端配置（Vercel）

`api/sync.js` 使用 Vercel KV（Upstash REST）作为存储层，需要以下环境变量：

- `KV_REST_API_URL`
- `KV_REST_API_TOKEN`

未配置时，前端会提示“服务端尚未配置云存储”。

### 3. 同步策略

- 默认采用“本地优先 + 时间戳比较”
- 智能同步时：
- 云端为空 -> 上传本地
- 本地较新 -> 上传本地
- 云端较新 -> 下载覆盖本地

## 🚀 部署指南

### Vercel 部署（推荐）

```bash
# 安装 Vercel CLI
npm i -g vercel

# 登录
vercel login

# 部署
vercel
```

### Netlify 部署

1. 拖拽项目文件夹到 [Netlify Drop](https://app.netlify.com/drop)
2. 或使用 Netlify CLI

### GitHub Pages 部署

```bash
# 推送到 GitHub
git add .
git commit -m "Initial commit"
git push origin main

# 在仓库设置中启用 GitHub Pages
# Settings -> Pages -> Source: main branch
```

## ♿ 可访问性

- ✅ WCAG 2.1 AA 级别对比度（4.5:1）
- ✅ 键盘导航支持
- ✅ 屏幕阅读器友好
- ✅ 动画可禁用（`prefers-reduced-motion`）
- ✅ 最小触摸目标 44x44px

## 📱 浏览器支持

- ✅ Chrome 90+
- ✅ Firefox 88+
- ✅ Safari 14+
- ✅ Edge 90+
- ✅ iOS Safari 14+
- ✅ Chrome Android 90+

## 📝 更新日志

### v1.0.0 (2025-02-25)

- 🎉 初始版本发布
- ✨ 学习模式（300 个核心词根）
- ✨ 闪卡复习模式
- ✨ 词根索引与搜索
- ✨ 进度追踪与成就系统
- 🎨 极简主义设计风格

## 🤝 贡献指南

欢迎贡献词根数据、UI 改进、bug 修复！

```bash
# Fork 项目
# 创建特性分支
git checkout -b feature/your-feature

# 提交更改
git commit -m "Add some feature"

# 推送到分支
git push origin feature/your-feature

# 创建 Pull Request
```

## 📄 开源协议

本项目采用 MIT 协议开源 - 详见 [LICENSE](../LICENSE) 文件

## 🙏 致谢

- 设计灵感: 极简主义设计哲学 - Less is More
- 字体: [Google Fonts - Inter](https://fonts.google.com/specimen/Inter)
- 词根数据参考: 各大词汇书籍和在线资源
- 部署平台: [Vercel](https://vercel.com) / [Netlify](https://netlify.com)

## 📧 联系方式

- **作者**: 乔帮主
- **X (Twitter)**: [@vista8](https://x.com/vista8)
- **微信公众号**: 向阳乔木推荐看
- **GitHub**: [@joeseesun](https://github.com/joeseesun)

---

⭐ 如果这个项目对你有帮助，欢迎 Star！

💬 有任何问题或建议，欢迎提 Issue 或 PR！
