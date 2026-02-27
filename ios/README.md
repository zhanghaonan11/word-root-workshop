# Word Root Workshop iOS (Native SwiftUI)

这个目录是原生 iOS 版本（SwiftUI），对应网页版的学习、闪卡、索引、详情、进度模块。

## 功能对齐

- 学习模式：词根详情 + 例词 + 小测
- 闪卡模式：翻面、前后切换、标记已掌握
- 词根索引：搜索 + 前缀/词根/后缀筛选
- 进度页：掌握统计、等级、连学天数、成就
- 本地存储：`UserDefaults`（键与网页版一致）
- 数据源：使用 `ios/data/wordData.js` 自动导出为 `wordRoots.json`

## 首次生成与运行

```bash
cd /Users/shan/github/word-root-workshop

# 1) 导出词根数据为 iOS 资源
node ios/scripts/export_word_roots_json.js

# 2) 生成 Xcode 工程
xcodegen generate --spec ios/project.yml

# 3) 打开工程
open ios/WordRootWorkshop.xcodeproj
```

在 Xcode 里选择 iOS Simulator 后直接运行 `WordRootWorkshop` scheme。

## 数据更新流程

更新 `ios/data/wordData.js` 后，重新执行：

```bash
node ios/scripts/export_word_roots_json.js
```

无需改 Swift 代码即可同步词库内容。

如果你希望从网页端一键同步到 iOS 数据源，可执行：

```bash
./ios/scripts/sync_from_web.sh
```
