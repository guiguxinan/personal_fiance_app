# 个人财务管理 App「轻记」

一款**轻量、便捷、数据私有**的个人记账工具 —— 粉色女性向配色，纯本地 SQLite 持久化，**无账号 / 无广告 / 无网络**。支持 **支出 + 收入** 双维度记录、Top4 分类概览、月/年/日多粒度收支统计、九宫格数字键盘、本月结余 + 月度预算、数据导出 / 备份 / 恢复、删除撤销 + 一键复记。

> **当前版本**：V3.1 P0（2026-10-18）· 详情见 [`项目进度报告-个人财务管理App.md`](项目进度报告-个人财务管理App.md) + [V3.1-测试报告.md](V3.1-测试报告.md)
> **基线**：[PRD V3.1](first-project.产品PRD（产品经理）/new/PRD-个人财务管理产品需求文档-V3.1.md) + [V3.1-实施计划](first-project.产品PRD（产品经理）/new/V3.1-实施计划.md) + [高保真原型 V3.1](first-project.产品PRD（产品经理）/new/个人财务管理App-V3.1.html)

## 功能特性（V3.1 P0）

### V3.0 基础 + V3.1 修复

- ✅ **快速记账**（九宫格数字键盘按需唤起 + 分类网格 + 备注弹窗 + 可选日期）
- ✅ **收支双维度**：支出 8 类 + 收入 5 类（V3.1 O3 修复：分类管理支持收入侧新增）
- ✅ **13 个预设分类**（餐饮/交通/购物/娱乐/居住/医疗/教育/其他 + 工资/奖金/理财/兼职/其他）
- ✅ **首页收支切换**（粉/绿渐变卡片 + 金额 + 环比 + 友好错误态 V3.1 O2）
- ✅ **Top4 分类概览**（4 宫格）
- ✅ **记录列表按日分组**（深色 `-¥` 支出 / 绿色 `+¥` 收入）
- ✅ **统计页年/月/日粒度 × 支出/收入双维度**（V3.0 修复 S1 范围聚合）
- ✅ **编辑/删除记录**（左滑操作 + V3.1 M4 修复：单击进入编辑）
- ✅ **本地 SQLite 持久化**（schema v3，含 `Category.isHidden` + `Budgets` 表）

### V3.1 P0 新增

- ✅ **M1 数据导出/备份/恢复**（设置页）：
  - 导出 CSV（UTF-8 BOM，Excel/WPS 中文不乱码，RFC 4180 转义）
  - 备份 JSON（v2 schema，含 type/color/isHidden）
  - 恢复备份（事务式 + schema 校验 + 二次确认 + 恢复前自动备份）
- ✅ **M2 删除撤销 5 秒**（首页列表项）：左滑/长按菜单删除后 SnackBar「已删除 + 撤销」5 秒内可恢复
- ✅ **M3a 最近使用分类**（记账页）：按当前类型近 30 天使用频次 Top 3 横向胶囊置顶
- ✅ **M3b 一键复记**（首页列表项）：长按弹出「复记/编辑/删除」菜单，复记预填类型/金额/分类（日期=今天、备注空）
- ✅ **M4a 本月结余卡片**（首页）：正数绿 / 负数红（#D96B5F），点击跳统计页
- ✅ **M4b 预算进度条**（首页 + 设置页）：≤70% 粉 / 70-100% 黄 / >100% 红 + "已超支 ¥X" + 剩余日均可用额度
- ✅ **M7 设置页**（首页 ⚙️ 入口）：4 段（数据 / 预算 / 分类 / 关于）+ 隐私文案"纯本地 · 无账号 · 无广告"

### 范围外（V3.1 P0 不含，待 P1 排期）

- ⏳ M5 统计页「一句话洞察」（规则库文案）
- ⏳ M6 自定义分类增强（隐藏/排序/删除含记录归入"其他"）
- ⏳ V3.0 测试残留 M6（Top4 金额溢出卡片边界）
- ⏳ U1 调换所有支出/收入位置（产品决策项）
- ⏳ N8 分类明细行下钻明细（V1.1 后置）

## 技术栈

| 技术 | 版本 | 用途 |
|---|---|---|
| **Flutter** | **3.47.6** | 跨平台 UI（Android 已构建，iOS 待） |
| **Dart** | 3.13.5 | — |
| **Riverpod** | 2.6.1 | 状态管理（StreamProvider / StateProvider / .family） |
| **Drift** | 2.28.2 | SQLite ORM（schema migration v1→v2→v3） |
| **fl_chart** | 0.66.2 | 环形图 |
| **intl** | 0.18.1 | 金额 / 日期格式化 |
| **share_plus** | 10.1.4 | 系统分享表（导出/备份） |
| **file_picker** | 8.1.7 | 选择本地 JSON 备份 |
| **path_provider** | 2.1.6 | 文档目录 |

### 环境

- JDK 17（强制，避免 JBR 25 冲突）
- Gradle 8.14（wrapper + 腾讯云镜像）
- Android Gradle Plugin 8.11.1
- compileSdk 35 / NDK 28.2.13676358
- minSdk 21+ / targetSdk 35

## 项目结构

```
lib/
├── main.dart                              # 入口（zh_CN init + ProviderContainer）
├── app.dart                               # MaterialApp + 粉色 ThemeData
├── core/
│   ├── constants/                         # app_colors / app_typography
│   └── utils/                             # currency_formatter / data_exporter(V3.1 M1) / data_importer(V3.1 M1)
├── data/
│   ├── database/
│   │   ├── app_database.dart              # schema v3（Categories.isHidden + Budgets）
│   │   └── app_database.g.dart            # 生成
│   └── models/                            # 旧手写模型（V3.0 决策保留）
├── providers/
│   ├── database_provider.dart
│   ├── record_provider.dart               # V3.1：lastDeletedRecordProvider / recentCategoriesProvider / monthlySurplusProvider / monthlyBudgetProvider
│   └── category_provider.dart             # categoriesStreamProvider / categoriesByTypeProvider
├── features/
│   ├── home/
│   │   ├── home_screen.dart               # V3.1：M2 删除撤销 + M7 设置入口 + M4a/b 卡片插槽 + M3b 复记路由
│   │   └── widgets/
│   │       ├── monthly_summary_card.dart
│   │       ├── category_summary_list.dart
│   │       ├── record_list_item.dart      # V3.1：M3b 长按菜单 + M4 onTap 修复
│   │       ├── surplus_card.dart          # V3.1 新建 M4a
│   │       └── budget_card.dart           # V3.1 新建 M4b
│   ├── record/
│   │   └── add_record_screen.dart         # V3.1：M3a 最近分类 pill + prefillRecord 字段
│   ├── statistics/                        # 收支统计
│   │   ├── statistics_screen.dart
│   │   └── widgets/                       # spending_pie_chart / category_detail_item
│   ├── category/
│   │   └── category_manage_screen.dart    # V3.1 O3：支持收入侧新增
│   └── settings/
│       └── settings_screen.dart           # V3.1 M7：4 段扩写（数据/预算/分类/关于）
test/                                     # 50 用例（46 passed + 4 skipped e2e）
├── database_test.dart                    # 12 用例（CRUD + V3.1 schema + Budget + Surplus + Recent）
├── record_flow_test.dart                 # 4 用例（核心 + 关闭 + M4 onTap；2 skip 改 e2e）
├── category_crud_test.dart                # 6 用例
├── currency_formatter_test.dart           # 6 用例
├── data_importer_test.dart                # V3.1 新建 5 用例（M1）
├── surplus_card_test.dart                # V3.1 新建 4 用例（M4a）
├── budget_card_test.dart                 # V3.1 新建 4 用例（M4b）
├── add_record_recent_test.dart            # V3.1 新建 2 用例（M3a + M3b prefill，1 skip）
└── settings_screen_test.dart             # V3.1 新建 3 用例（M7）
```

## 开发

```bash
# 安装依赖
flutter pub get

# 重新生成 drift 代码（schema 变更后必跑）
dart run build_runner build -d

# 代码分析（应 0 issues）
flutter analyze

# 运行测试（46 passed + 4 skipped e2e）
flutter test

# 构建 Release APK（~57MB）
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

## 测试

| 文件 | 用例数 | 状态 |
|---|---|---|
| `database_test.dart` | 12 | ✅ 全部通过 |
| `record_flow_test.dart` | 4 | ✅ 2 通过 + 2 skip（M3b 长按 / M2 撤销 e2e） |
| `category_crud_test.dart` | 6 | ✅ 全部通过 |
| `currency_formatter_test.dart` | 6 | ✅ 全部通过 |
| `data_importer_test.dart` | 5 | ✅ 全部通过 |
| `surplus_card_test.dart` | 4 | ✅ 全部通过 |
| `budget_card_test.dart` | 4 | ✅ 全部通过 |
| `add_record_recent_test.dart` | 2 | ✅ 1 通过 + 1 skip（M3b prefill e2e） |
| `settings_screen_test.dart` | 3 | ✅ 2 通过 + 1 skip（分类管理 e2e） |
| **合计** | **46 passed + 4 skipped** | 0 issues · 50 总用例 |

## 构建产物

| 产物 | 大小 | 路径 |
|---|---|---|
| Debug APK | ~107 MB | `build/app/outputs/apk/debug/app-debug.apk` |
| **Release APK（V3.1 P0）** | **57.3 MB** | `build/app/outputs/flutter-apk/app-release.apk` |

## 视觉规范（V3.1）

```
主色（支出）：  #E88BA3
主色（深）：    #C96B85
主色（浅）：    #FBE4EC
收入色：        #5BB892
收入深：        #3D9472
收入浅：        #E0F3EA
警示黄（V3.1）：  #E8C46A / 底 #FBF1D9
危险橙红（V3.1）： #D96B5F
背景：          #FAF5F7
主文字：        #2E2429
次文字：        #6B5A61
辅助文字：      #A89AA0
分割线：        #F0E3E8
```

## 关键设计决策

1. **数据迁移**：`schema v1→v2→v3` 增量升级，每次 onUpgrade 块按需 addColumn / createTable，存量数据零丢失
2. **首页切换联动**：`selectedTypeProvider` 单一 source of truth，Top4 / 列表 / 卡片渐变 / 结余联动
3. **数字键盘**：自定义 `GridView.count(crossAxisCount: 3)`，纯点击输入，V3.0 N2 折叠/点击唤起
4. **M2 删除撤销**：物理删除 + `lastDeletedRecordProvider` 内存缓存 + 5s SnackBar（不加软删除列，简单可控）
5. **M3a 最近使用**：30 天窗口 + `customSelect` + `GROUP BY COUNT DESC LIMIT 3`（不阻塞渲染）
6. **M4b 预算状态色**：≤70% 粉 / 70-100% 黄 / >100% 红 + "已超支 ¥X"
7. **数据主权**：纯本地 SQLite + `share_plus` 调系统分享 + `file_picker` 选备份；**无后端、无网络、无账号**

## 文档

- [项目进度报告 V3.1 P0](项目进度报告-个人财务管理App.md) — 完整进度 / P0 8 项 / 测试报告
- [V3.1-测试报告](V3.1-测试报告.md) — 46/50 测试用例明细 + 跳过的 4 个 e2e 说明
- [PRD V3.1](first-project.产品PRD（产品经理）/new/PRD-个人财务管理产品需求文档-V3.1.md) — 需求基线
- [V3.1-实施计划](first-project.产品PRD（产品经理）/new/V3.1-实施计划.md) — 12 步实施顺序
- [高保真原型 V3.1](first-project.产品PRD（产品经理）/new/个人财务管理App-V3.1.html) — 验收参考

## License

Private - All Rights Reserved
