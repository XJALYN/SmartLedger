# SmartLedger

[English README](README.md)

**SmartLedger** 是一款 AI 驱动的 iOS 智能记账应用。支持文字、语音或小票拍照输入，AI 自动提取消费明细，确认后保存至可搜索账本，并提供多维度支出统计。

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Tests](https://img.shields.io/badge/tests-53%20passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

**项目主页：** [https://XJALYN.github.io/SmartLedger/](https://XJALYN.github.io/SmartLedger/)

---

## 功能特性

### AI 聊天记账
- 自然语言记账与消费查询
- 语音输入（Speech 框架）
- 相机或相册小票识别
- 接入 [阿里云百炼 DashScope](https://www.aliyun.com/product/bailian) — 文本使用 `qwen-plus`，视觉使用 `qwen-vl-max`
- 未配置 API Key 时使用离线 mock 解析

### 确认保存
- 可编辑 AI 提取的标题、金额、日期、分类、商户、备注
- 小票预览及税费明细
- 10 类支出分类（含 emoji）

### 支出账本
- 按日分组展示
- 按标题、商户搜索
- 按分类筛选
- 左滑删除

### 消费统计
- 周 / 月 / 年 / 自定义时间范围
- 分类占比环形图
- 每日支出柱状图
- 月度预算进度

### 设置
- AI 算力积分与 App Store 内购充值（StoreKit 2）
- 5 种主题色：薄荷、天蓝、紫罗兰、玫瑰、琥珀
- 语言切换：跟随系统 / 英语 / 简体中文
- 多货币支持（CNY、USD、EUR 等）
- 导出 CSV / JSON / PDF
- 通知开关、Face ID 偏好

---

## 截图

| 聊天 | 确认 | 账本 | 统计 | 设置 |
|------|------|------|------|------|
| ![AI 聊天记账](AI%20Assistant%20Chat.png) | ![确认消费](Confirm%20Expense.png) | ![支出账本](Expense%20Ledger.png) | ![消费统计](Spending%20Analytics.png) | ![设置与积分](Settings%20%26%20Credits.png) |

---

## 环境要求

| 项目 | 说明 |
|------|------|
| **Xcode** | 15.0+（Swift 5，iOS 17 SDK） |
| **iOS 部署目标** | 17.0 |
| **设备** | iPhone（仅竖屏） |
| **Bundle ID** | `com.smartledger.app` |
| **版本** | 2.4.1（Build 2048） |

### 系统权限

应用会请求以下权限（见 `Info.plist`）：

| 权限 | 用途 |
|------|------|
| 相机 | 拍摄小票供 AI 识别 |
| 相册 | 上传小票图片 |
| 麦克风 | 语音记账 |
| 语音识别 | 将语音转为文字 |

### 外部服务

| 服务 | 是否必需 | 用途 |
|------|----------|------|
| [DashScope API](https://help.aliyun.com/zh/model-studio/) | 可选* | AI 文本与小票视觉识别 |
| App Store Connect | 可选 | 内购算力积分（StoreKit 2） |

\* 未配置 API Key 时，应用会回退到本地正则解析器。完整 AI 能力（尤其是小票 OCR）需要 DashScope Key。

---

## 快速开始

### 1. 克隆仓库

```bash
git clone https://github.com/XJALYN/SmartLedger.git
cd SmartLedger
```

### 2. 配置 API Key（可选，建议配置）

复制示例密钥文件并填入 DashScope API Key：

```bash
cp iOS/SmartLedger/Resources/Secrets.example.plist \
   iOS/SmartLedger/Resources/LocalSecrets.plist
```

编辑 `LocalSecrets.plist`：

```xml
<key>DashScopeAPIKey</key>
<string>YOUR_DASHSCOPE_API_KEY_HERE</string>
```

> **重要：** `LocalSecrets.plist` 已列入 `.gitignore`，切勿提交到仓库。Key 可在 [阿里云百炼](https://www.aliyun.com/product/bailian) 获取。若曾误推到远程，请立即在阿里云控制台**轮换密钥**。

首次启动时，若 UserDefaults 中尚无 Key，应用会从 `LocalSecrets.plist` 读取。

### 3. 用 Xcode 打开

```bash
open iOS/SmartLedger.xcodeproj
```

选择 **SmartLedger** Scheme，指定 iPhone 模拟器或真机，按 **⌘R** 编译运行。

### 4. StoreKit 测试（可选）

项目包含 `Products.storekit` 用于本地内购测试。在 **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration** 中启用。

---

## 项目结构

```
SmartLedger/
├── README.md
├── README.zh-CN.md
├── iOS/
│   ├── SmartLedger.xcodeproj/       # Xcode 工程
│   ├── SmartLedger/
│   │   ├── App/                     # 入口与 AppState
│   │   ├── Models/                  # Expense、AppSettings、DesignTokens
│   │   ├── Services/                # BailianService、ExpenseStore、统计、导出、StoreKit
│   │   ├── Views/
│   │   │   ├── Chat/                # AI 聊天界面
│   │   │   ├── Confirm/             # 消费确认表单
│   │   │   ├── Ledger/              # 账单列表
│   │   │   ├── Stats/               # 统计仪表盘
│   │   │   ├── Settings/            # 设置与积分
│   │   │   └── Components/          # Tab 栏、图片选择器等共用组件
│   │   └── Resources/
│   │       ├── Info.plist
│   │       ├── Assets.xcassets
│   │       ├── Products.storekit    # StoreKit 测试配置
│   │       ├── Secrets.example.plist
│   │       ├── LocalSecrets.plist   # 已忽略 — 你的 API Key
│   │       └── *.lproj/             # 本地化（en、zh-Hans、ja、es、de、fr）
│   ├── SmartLedgerTests/            # 47 个单元测试
│   ├── SmartLedgerUITests/          # 6 个 UI 测试
│   └── TEST_VERIFICATION.md         # 详细测试报告
├── SmartLedger/                     # HTML 设计原型（参考）
└── *.png                            # 应用截图
```

### 技术栈

| 层级 | 技术 |
|------|------|
| UI | SwiftUI |
| 存储 | UserDefaults（JSON 序列化账单） |
| AI | DashScope OpenAI 兼容 API（`qwen-plus`、`qwen-vl-max`） |
| 内购 | StoreKit 2 |
| 语音 | Speech + AVFoundation |
| 测试 | XCTest + XCUITest |
| 依赖 | 无（无 SPM / CocoaPods，仅 Apple 框架） |

> **说明：** 暂未实现云同步与 SwiftData/CloudKit，数据仅保存在本机。

---

## 配置说明

### API Key

| 方式 | 位置 | 说明 |
|------|------|------|
| 构建时注入 | `iOS/SmartLedger/Resources/LocalSecrets.plist` | 开发推荐；已 gitignore |
| 运行时 | UserDefaults 键 `sl.dashscopeApiKey` | 可编程设置或未来设置页 |

各 AI 操作消耗的算力积分：

| 操作 | 积分 |
|------|------|
| 消费查询 | 2 |
| 普通聊天 | 2 |
| 文本记账解析 | 5 |
| 小票图片解析 | 10 |

### 本地化

字符串资源位于 `Resources/*.lproj/Localizable.strings`，支持 **英语**、**简体中文**、**日语**、**西班牙语**、**德语**、**法语**。

应用内语言选项为 **跟随系统**、**英语**、**简体中文**；其他语言随系统语言自动匹配。

### 主题

默认主色为薄荷绿（`#4ADE80`）。设置中可选 5 套主题配色。

---

## 测试

命令行运行全部测试：

```bash
cd iOS
xcodebuild test \
  -scheme SmartLedger \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

| 测试套件 | 数量 | 覆盖范围 |
|----------|------|----------|
| `SmartLedgerTests` | 47 | ExpenseStore、统计、BailianService、导出、AppSettings、本地化、分类、StoreKit |
| `SmartLedgerUITests` | 6 | Tab 导航、聊天输入、手动记账、账本搜索、统计切换、主题选择 |
| **合计** | **53** | |

UI 测试以 `UI_TESTING` 参数启动（跳过评分弹窗、注入示例数据）。

详见 [`iOS/TEST_VERIFICATION.md`](iOS/TEST_VERIFICATION.md) 中的功能与测试对照。

---

## 贡献指南

欢迎贡献！建议流程：

1. **Fork** 仓库，从 `main` 创建功能分支。
2. **遵循现有风格** — SwiftUI 模式、`DesignTokens` 配色间距、用户可见文案均走本地化。
3. **补充或更新测试** — 在 `SmartLedgerTests` 或 `SmartLedgerUITests` 中覆盖新行为。
4. **切勿提交密钥** — 勿将 `LocalSecrets.plist` 纳入版本控制。可选预提交钩子：`cp scripts/check-secrets.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
5. **提交 Pull Request** — 说明改动内容与测试结果。

较大功能或架构调整请先开 Issue 讨论。

---

## 已知限制

- **仅本地存储** — 无 iCloud 同步（设计稿中有占位）
- **仅浅色模式** — 有意关闭深色模式
- **仅竖屏** — 不支持横屏
- **内购商品** — 正式环境需在 App Store Connect 配置；本地使用 `Products.storekit` 测试

---

## 致谢

- **[阿里云百炼 / DashScope](https://www.aliyun.com/product/bailian)** — Qwen 模型用于 AI 记账解析
- **[Qwen](https://github.com/QwenLM/Qwen)** — 底层大语言与视觉模型
- `SmartLedger/` 中的 UI 设计原型为 SwiftUI 实现提供视觉参考

---

## 联系方式

| 项目 | 内容 |
|------|------|
| **平台** | 抖音 |
| **用户名** | @开发1000个应用 |
| **抖音号** | KZTY52 |

> ❤️ 用编程治愈妄想症，亲手做出1000APP

在抖音搜索 **KZTY52** 或 **@开发1000个应用** 关注开发者，或扫描下方二维码。

<p align="center">
  <img src="concat.jpg" alt="抖音主页二维码" width="200">
  <br>
  <sub>抖音扫码关注</sub>
</p>

---

## 许可证

本项目采用 [MIT License](LICENSE)。

---

<p align="center">
  SmartLedger v2.4.1 · Made with SwiftUI
</p>
