# Changelog

## v0.1 - 2026-03-02

### Added
- 基线版本的 UX/性能迭代记录，建立后续 `v0.2+` 的增量对照点。

### Improved
- 启动阶段：`WordRootRepository` 将重复 ID 校验与 ID 索引构建迁移到后台线程，减少主线程启动负载。
- 启动 I/O：`wordRoots.json` 读取改为 `Data(contentsOf:options: [.mappedIfSafe])`，降低大文件加载时的内存与阻塞压力。
- 索引搜索：`RootsIndexView` 引入后台构建索引、可取消任务与 180ms 防抖过滤，减少输入时掉帧与卡顿。
- 索引搜索：新增重复条件签名检查，避免同一查询/分类组合反复触发后台过滤。
- 索引列表：将行展示数据（含例词预览）在建索引阶段预计算，减少滚动与筛选期间的行内重复拼接开销。
- 索引渲染：词根列表行改为 `Equatable` 渲染，降低父视图状态变化带来的无效重绘。
- 索引生命周期：页面重复进入时优先复用已有索引，避免每次 `onAppear` 全量重建。
- 索引体验：搜索过程中展示“筛选中...”状态，避免频繁闪烁空态。
- 闪卡交互：移除拖拽过程的隐式逐帧动画，改为释放时回弹；使用 `predictedEndTranslation` 提升滑动翻卡判定响应。
- 触觉反馈：闪卡页面复用 haptic generator，减少重复创建带来的反馈延迟。

### Verified
- 本地构建验证通过：
  - `xcodebuild -project WordRootWorkshop.xcodeproj -scheme WordRootWorkshop -destination 'generic/platform=iOS Simulator' -derivedDataPath build/DerivedData build`
