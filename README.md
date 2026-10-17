# 个人财务管理 App

一款**轻量、便捷**的个人记账工具「**轻记 V2**」—— 粉色女性向配色，支持 **支出 + 收入** 双维度记录、Top4 分类概览、月/年/日多粒度收支统计、九宫格数字键盘、横向日期条拖拽。

> **当前版本**：V2.1（2026-10-17）· 详情见 [`项目进度报告-个人财务管理App.md`](项目进度报告-个人财务管理App.md)
> **基线**：[PRD V2.1](first-project.产品PRD（产品经理）/PRD-个人财务管理产品需求文档-V2.md) + [高保真原型 V3](first-project.产品PRD（产品经理）/个人财务管理App-V3.html)

## 功能特性

### P0 核心

- ✅ **快速记账**（9 宫格数字键盘 + 分类网格 + 备注）
- ✅ **收支双维度**：支出 8 类 + 收入 5 类
- ✅ **13 个预设分类**（餐饮/交通/购物/娱乐/居住/医疗/教育/其他 + 工资/奖金/理财/兼职/其他）
- ✅ **首页收支切换**（粉色 / 绿色渐变卡片 + 金额 + 环比）
- ✅ **Top4 分类概览**（4 宫格展示金额最高 4 个分类）
- ✅ **记录列表按日分组**（深色 `-¥` 支出 / 绿色 `+¥` 收入 + 笔数 + 当日合计）
- ✅ **统计页年/月/日粒度 × 支出/收入双维度**（横向滑动日期条 + 环形图 + 分类明细）
- ✅ **编辑/删除记录**（左滑操作）
- ✅ **本地 SQLite 持久化**（schema v2，含 `type`/`color` 字段）

### P1 体验

- ✅ **备注输入**（最多 100 字）
- ✅ **金额 9 位长度限制 + 小数点去重**
- ✅ **环形图**（donut + 中心显示「类型 + 总额」两行）
- ✅ **分类明细**（色点 + 占比百分比 + 进度条）
- ✅ **保存后自动联动首页切类型**（记一笔收入 → 自动回首页 → 收入视图）
- ✅ **空状态友好提示**（「还没有记录，点下方 + 记一笔吧～」）

### P2 规划（V2.1 暂不触达）

- ⏳ 自定义分类管理（文件已实现，入口未在 V2.1 暴露）
- ⏳ 数据备份/恢复（JSON 导出/导入）
- ⏳ 饼图点击下钻分类明细

## 技术栈

| 技术 | 版本 | 用途 |
|---|---|---|
| **Flutter** | **3.47.6** | 跨平台 UI（Android 已构建，iOS 待） |
| **Dart** | 3.13.5 | — |
| **Riverpod** | 2.6.1 | 状态管理（StreamProvider / StateProvider） |
| **Drift** | 2.28.2 | SQLite ORM（含 schema migration v1→v2） |
| **fl_chart** | 0.66.2 | 环形图 |
| **intl** | 0.18.1 | 金额 / 日期格式化 |
| **path_provider** | 2.1.6 | 文档目录 |

### 环境

- JDK 17（强制，避免 JBR 25 冲突）
- Gradle 8.14（wrapper + 腾讯云镜像）
- Android Gradle Plugin 8.11.1
- compileSdk 35 / NDK 26.1.10909125

## 项目结构

```
lib/
├── main.dart                      # 入口（zh_CN locale 初始化 + ProviderContainer）
├── app.dart                       # MaterialApp + 粉色 ThemeData
├── core/
│   ├── constants/
│   │   ├── app_colors.dart        # 粉色系 + 13 色 categoryColors
│   │   └── app_typography.dart
│   └── utils/
│       ├── currency_formatter.dart  # 千分位 / 紧凑 / 无符号
│       ├── data_exporter.dart       # P2（V2.1 暂不用）
│       └── data_importer.dart       # P2（V2.1 暂不用）
├── data/
│   ├── database/
│   │   ├── app_database.dart      # schema v2（type/color 字段）
│   │   └── app_database.g.dart    # 生成
│   └── models/                    # 旧手写模型（待清理）
├── providers/
│   ├── database_provider.dart
│   ├── record_provider.dart       # selectedTypeProvider / prevMonthTotalProvider
│   └── category_provider.dart     # categoriesStreamProvider / categoriesByTypeProvider
├── features/
│   ├── home/                      # 首页（收支切换 + Top4 + 列表）
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       ├── monthly_summary_card.dart
│   │       ├── category_summary_list.dart
│   │       └── record_list_item.dart
│   ├── record/add_record_screen.dart   # 9 宫格数字键盘
│   ├── statistics/                # 收支统计（年/月/日）
│   │   ├── statistics_screen.dart
│   │   └── widgets/
│   │       ├── spending_pie_chart.dart
│   │       └── category_detail_item.dart
│   ├── category/category_manage_screen.dart  # P2
│   └── settings/settings_screen.dart          # P2
test/                              # 19 个测试用例
├── database_test.dart             # 8 用例（含 V2.1 type/color 断言）
├── currency_formatter_test.dart    # 6 用例
├── category_crud_test.dart         # 4 用例
└── record_flow_test.dart          # 2 用例（数字键盘点击）
```

## 开发

```bash
# 安装依赖
flutter pub get

# 代码分析（应 0 issues）
flutter analyze

# 运行测试（应 19/19 通过）
flutter test

# 构建 Debug APK
flutter build apk --debug
# → build/app/outputs/apk/debug/app-debug.apk (~106MB)

# 构建 Release APK
flutter build apk --release
# → build/app/outputs/apk/release/app-release.apk (~58MB)
```

## 测试

| 测试文件 | 用例数 | 覆盖内容 |
|---|---|---|
| `database_test.dart` | 8 | 建库（13 默认分类 + type/color）/ CRUD / 月份过滤 / 按类型聚合 |
| `currency_formatter_test.dart` | 6 | 千分位 / 紧凑 / 无符号 |
| `category_crud_test.dart` | 4 | 插入/更新/删除自定义分类 + watch 流 |
| `record_flow_test.dart` | 2 | 空首页→记账→展示（数字键盘点击） / 关闭无输入直接返回 |
| **合计** | **20** | — |

**19+ tests passed**（V2.1 全过）· 0 issues

## 构建产物

| 产物 | 大小 | 路径 |
|---|---|---|
| Debug APK | 106.7 MB | `build/app/outputs/apk/debug/app-debug.apk` |
| Release APK | 57.9 MB | `build/app/outputs/apk/release/app-release.apk` |

## 视觉规范（V2.1）

```
主色（支出）：  #E88BA3
主色（深）：    #C96B85
主色（浅）：    #FBE4EC
收入色：        #5BB892
收入深：        #3D9472
收入浅：        #E0F3EA
背景：          #FAF5F7
主文字：        #2E2429
次文字：        #6B5A61
辅助文字：      #A89AA0
分割线：        #F0E3E8
```

## 关键设计决策

1. **数据迁移**：`schema v1→v2` 升级时，存量记录默认归入 `expense`（PRD §0.1 C5）
2. **首页切换联动**：`selectedTypeProvider` 单一 source of truth，Top4 / 列表 / 卡片渐变 / 总览金额全部 watch 它
3. **数字键盘**：自定义 `GridView.count(crossAxisCount: 3)`，纯点击输入，避免调起系统键盘
4. **分类查找**：所有 UI 走 `ref.watch(categoryByIdProvider(id))` / `categoriesByTypeProvider(type)`，**不再用静态 `defaultCategories`**，避免收入 5 类查不到
5. **环形图**：fl_chart `PieChartData(centerSpaceRadius: 70)` + 中心两行（label 12px 灰 + amount 15px 粗），颜色取自 `category.color`

## 文档

- [项目进度报告 V2.1](项目进度报告-个人财务管理App.md) — 完整进度 / 修复明细 / 风险
- [原型V2.1与实现差异分析](原型V2.1与实现差异分析.md) — 升级前的 6 项 P0 缺口 + 11 项修复对照
- [PRD V2.1](first-project.产品PRD（产品经理）/PRD-个人财务管理产品需求文档-V2.md) — 需求基线
- [高保真原型 V3](first-project.产品PRD（产品经理）/个人财务管理App-V3.html) — 验收参考

## License

Private - All Rights Reserved
