# word-root-workshop

当前仓库已拆分为两个独立项目：

- `web/`：网页端（原生 HTML/CSS/JavaScript + Vercel Function）
- `ios/`：iOS 原生端（SwiftUI）

## 目录结构

```text
word-root-workshop/
├── web/
│   ├── index.html
│   ├── api/
│   ├── css/
│   ├── js/
│   └── README.md
├── ios/
│   ├── WordRootWorkshop/
│   ├── WordRootWorkshop.xcodeproj/
│   ├── scripts/
│   └── README.md
└── LICENSE
```

## 快速开始

### Web

```bash
cd web
python3 -m http.server 8000
```

### iOS

```bash
node ios/scripts/export_word_roots_json.js
xcodegen generate --spec ios/project.yml
open ios/WordRootWorkshop.xcodeproj
```
