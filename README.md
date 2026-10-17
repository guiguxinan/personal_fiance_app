# 个人财务管理 App

一款轻量、便捷的个人记账工具，支持支出记录、分类统计、月度汇总。

## 功能特性

- ✅ 快速记账（金额 + 分类 + 日期 + 备注）
- ✅ 8 个预设分类（餐饮、交通、购物、娱乐、居住、医疗、教育、其他）
- ✅ 记录列表按日分组展示
- ✅ 月度总支出统计
- ✅ 分类占比饼图
- ✅ 编辑 / 删除记录
- ✅ 本地 SQLite 持久化

## 技术栈

| 技术 | 版本 |
|------|------|
| Flutter | 3.24.0 |
| Riverpod | 2.6 |
| Drift (SQLite) | 2.23 |
| fl_chart | 0.66 |

## 项目结构

```
lib/
├── main.dart                  # 入口
├── app.dart                   # App 配置
├── core/
│   ├── constants/             # 颜色、字体常量
│   └── utils/                 # 货币格式化工具
├── data/
│   ├── database/             # Drift 数据库
│   └── models/                # 数据模型
├── features/
│   ├── home/                  # 首页
│   ├── record/                # 记账页
│   └── statistics/            # 统计页
└── providers/                 # Riverpod 状态管理
```

## 开发

```bash
# 安装依赖
flutter pub get

# 代码分析
flutter analyze

# 运行测试
flutter test

# 构建 Debug APK
flutter build apk --debug

# 构建 Release APK
flutter build apk --release
```

## 测试

| 测试文件 | 覆盖内容 |
|---|---|
| `database_test.dart` | 建库/CRUD/月份过滤/聚合查询 |
| `currency_formatter_test.dart` | 金额格式化/千分位/紧凑格式 |
| `record_flow_test.dart` | 核心记账流程 Widget Test |

**15/15 tests passed**

## 构建产物

| 产物 | 大小 | 路径 |
|---|---|---|
| Debug APK | 87 MB | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | 23.5 MB | `build/app/outputs/flutter-apk/app-release.apk` |

## License

Private - All Rights Reserved
