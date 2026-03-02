# Changelog

## v0.3 - 2026-03-02

### Improved
- 闪卡交互隔离：将拖拽/翻面状态下沉到独立的 `FlashcardInteractiveCard`，减少父视图在手势过程中的无关重绘。
- 闪卡手势流畅度：拖拽反馈增加轻微缩放与方向提示，滑动判定保持 `predictedEndTranslation`，提升跟手感与可预期性。
- 闪卡状态一致性：切换卡片时独立卡片状态自动重置，避免翻面/拖拽残留影响下一张卡片。
- 进度持久化性能：`ProgressStore` 写入改为后台队列 + 防抖合并，降低高频学习交互时主线程 I/O 抖动。
- 数据一致性：新增 `flushPendingWrites()`，在 `scenePhase` 切换到 `inactive/background` 时强制落盘，减少后台切换导致的数据丢失风险。
- 导入/清空一致性：导入与清空学习数据走立即持久化路径，确保关键操作结果可恢复。

### Verified
- 本地构建验证通过：
  - `xcodebuild -project WordRootWorkshop.xcodeproj -scheme WordRootWorkshop -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build`

## v0.2 - 2026-03-02

### Added
- 启动持久化缓存：新增 Application Support 缓存文件 `word_roots_cache_v1.plist`，缓存已解析词根与搜索索引。
- 缓存版本治理：缓存 payload 增加 `schemaVersion` 与源数据 `SHA256` 摘要字段。

### Improved
- 启动性能：当 `wordRoots.json` 内容未变化时，优先读取持久化缓存，跳过 JSON 重新解析与索引重建。
- 缓存失效：当 `wordRoots.json` 变更（摘要不一致）或 schema 版本不匹配时，自动回退重建并刷新缓存。
- 仓储层：`WordRootRepository` 统一产出 `searchIndex`，避免页面层在每次启动后重复生成 searchable 文本。
- 列表渲染：`RootsIndexView` 直接消费预构建索引记录，行内容改为稳定标识+预格式化字段，进一步减少滚动时计算开销。
- 列表筛选：筛选阶段只做分类和字符串匹配，不再重复进行例词拼接或 searchable 文本构建。

### Verified
- 本地构建验证通过：
  - `xcodebuild -project WordRootWorkshop.xcodeproj -scheme WordRootWorkshop -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build`

## v0.1 - 2026-03-02

### Added
- 基线版本的 UX/性能迭代记录，建立后续 `v0.2+` 的增量对照点。

### Improved
- 启动阶段：`WordRootRepository` 将重复 ID 校验与 ID 索引构建迁移到后台线程，减少主线程启动负载。
- 启动 I/O：`wordRoots.json` 读取改为 `Data(contentsOf:options: [.mappedIfSafe])`，降低大文件加载时的内存与阻塞压力。
- 启动缓存：按 `bundlePath` 缓存已解码词根快照，避免同一进程内重复加载/重复解码。
- 启动并发控制：同一资源路径加载进行去重，避免短时间重复触发并发加载任务。
- 索引搜索：`RootsIndexView` 引入后台构建索引、可取消任务与 180ms 防抖过滤，减少输入时掉帧与卡顿。
- 索引搜索：新增重复条件签名检查，避免同一查询/分类组合反复触发后台过滤。
- 索引列表：将行展示数据（含例词预览）在建索引阶段预计算，减少滚动与筛选期间的行内重复拼接开销。
- 索引渲染：词根列表行改为 `Equatable` 渲染，降低父视图状态变化带来的无效重绘。
- 索引生命周期：页面重复进入时优先复用已有索引，避免每次 `onAppear` 全量重建。
- 索引体验：搜索过程中展示“筛选中...”状态，避免频繁闪烁空态。
- 闪卡手势：改为 `@GestureState` 驱动拖拽位移，减少拖拽过程对持久状态的逐帧写入。
- 闪卡动画：卡片倾斜角度增加上限约束并保留弹簧回弹，提升滑动过程稳定性与可控性。
- 闪卡交互：继续使用 `predictedEndTranslation` 判定翻卡方向，降低慢速滑动误判。
- 触觉反馈：闪卡页面复用 haptic generator，减少重复创建带来的反馈延迟。

### Verified
- 本地构建验证通过：
  - `xcodebuild -project WordRootWorkshop.xcodeproj -scheme WordRootWorkshop -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build`
