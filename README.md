# SmartLedger

**SmartLedger** is an AI-powered personal expense tracker for iOS. Talk, type, or snap a receipt — the assistant extracts expense details, lets you confirm and edit them, and saves everything to a searchable ledger with spending analytics.

**SmartLedger** 是一款 AI 驱动的 iOS 智能记账应用。支持文字、语音或小票拍照输入，AI 自动提取消费明细，确认后保存至可搜索账本，并提供多维度支出统计。

![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![Tests](https://img.shields.io/badge/tests-53%20passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Features / 功能特性

### AI Assistant Chat / AI 聊天记账
- Natural-language expense recording and spending queries / 自然语言记账与消费查询
- Voice input via Speech framework / 语音输入（Speech 框架）
- Receipt capture from camera or photo library / 相机或相册小票识别
- Powered by [Alibaba Cloud Bailian (DashScope)](https://www.aliyun.com/product/bailian) — `qwen-plus` for text, `qwen-vl-max` for vision / 接入阿里云百炼 DashScope
- Offline fallback parser when no API key is configured / 未配置 API Key 时使用离线 mock 解析

### Confirm & Save / 确认保存
- Review and edit AI-extracted fields: title, amount, date, category, merchant, notes / 可编辑 AI 提取的标题、金额、日期、分类、商户、备注
- Receipt preview with subtotal / tax breakdown / 小票预览及税费明细
- 10 expense categories with emoji icons / 10 类支出分类（含 emoji）

### Expense Ledger / 支出账本
- Chronological list grouped by day / 按日分组展示
- Search by title or merchant / 按标题、商户搜索
- Filter by category / 按分类筛选
- Swipe to delete / 左滑删除

### Spending Analytics / 消费统计
- Time ranges: week, month, year, custom / 周 / 月 / 年 / 自定义范围
- Category breakdown (donut chart) / 分类占比环形图
- Daily spending bar chart / 每日支出柱状图
- Monthly budget progress / 月度预算进度

### Settings / 设置
- AI compute credits with StoreKit 2 in-app purchases / AI 算力积分与 App Store 内购充值
- Theme colors: Mint, Sky, Violet, Rose, Amber / 5 种主题色
- Language: System / English / 简体中文 / 语言切换
- Multi-currency support (CNY, USD, EUR, etc.) / 多货币支持
- Export ledger as CSV, JSON, or PDF / 导出 CSV / JSON / PDF
- Notifications toggle, Face ID preference / 通知开关、Face ID 偏好

---

## Screenshots / 截图

| Chat | Confirm | Ledger | Stats | Settings |
|------|---------|--------|-------|----------|
| ![AI Assistant Chat](AI%20Assistant%20Chat.png) | ![Confirm Expense](Confirm%20Expense.png) | ![Expense Ledger](Expense%20Ledger.png) | ![Spending Analytics](Spending%20Analytics.png) | ![Settings & Credits](Settings%20%26%20Credits.png) |

---

## Requirements / 环境要求

| Requirement | Value |
|-------------|-------|
| **Xcode** | 15.0+ (Swift 5, iOS 17 SDK) |
| **iOS Deployment Target** | 17.0 |
| **Device** | iPhone (Portrait only) |
| **Bundle ID** | `com.smartledger.app` |
| **Version** | 2.4.1 (Build 2048) |

### Permissions / 系统权限

The app requests the following capabilities (see `Info.plist`):

| Permission | Purpose |
|------------|---------|
| Camera | Capture receipt photos for AI extraction |
| Photo Library | Upload receipt images |
| Microphone | Voice expense input |
| Speech Recognition | Convert voice to text |

### External Services / 外部服务

| Service | Required | Purpose |
|---------|----------|---------|
| [DashScope API](https://help.aliyun.com/zh/model-studio/) | Optional* | AI text & vision expense extraction |
| App Store Connect | Optional | In-app credit purchases (StoreKit 2) |

\* Without an API key, the app falls back to a local regex-based parser. Full AI features (especially receipt OCR) require a DashScope key.

---

## Getting Started / 快速开始

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd SmartLedger-images
```

### 2. Configure API key (optional but recommended)

Copy the example secrets file and add your DashScope API key:

```bash
cp iOS/SmartLedger/Resources/Secrets.example.plist \
   iOS/SmartLedger/Resources/LocalSecrets.plist
```

Edit `LocalSecrets.plist`:

```xml
<key>DashScopeAPIKey</key>
<string>YOUR_DASHSCOPE_API_KEY_HERE</string>
```

> **Important:** `LocalSecrets.plist` is listed in `.gitignore` and must never be committed. Obtain a key from [Alibaba Cloud Model Studio](https://www.aliyun.com/product/bailian). If a key was ever pushed to a remote, **rotate it immediately** in the Alibaba Cloud console.

On first launch, the app loads the key from `LocalSecrets.plist` if no key is stored in UserDefaults.

### 3. Open in Xcode

```bash
open iOS/SmartLedger.xcodeproj
```

Select the **SmartLedger** scheme, choose an iPhone simulator or device, and press **⌘R** to build and run.

### 4. StoreKit testing (optional)

The project includes `Products.storekit` for local IAP testing. Enable it under **Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration**.

---

## Project Structure / 项目结构

```
SmartLedger-images/
├── README.md
├── iOS/
│   ├── SmartLedger.xcodeproj/       # Xcode project
│   ├── SmartLedger/
│   │   ├── App/                     # App entry, AppState
│   │   ├── Models/                  # Expense, AppSettings, DesignTokens
│   │   ├── Services/                # BailianService, ExpenseStore, Analytics, Export, StoreKit
│   │   ├── Views/
│   │   │   ├── Chat/                # AI chat interface
│   │   │   ├── Confirm/             # Expense confirmation form
│   │   │   ├── Ledger/              # Transaction list
│   │   │   ├── Stats/               # Analytics dashboard
│   │   │   ├── Settings/            # Preferences & credits
│   │   │   └── Components/          # Tab bar, image picker, shared UI
│   │   └── Resources/
│   │       ├── Info.plist
│   │       ├── Assets.xcassets
│   │       ├── Products.storekit    # StoreKit test configuration
│   │       ├── Secrets.example.plist
│   │       ├── LocalSecrets.plist   # Gitignored — your API key
│   │       └── *.lproj/             # Localization (en, zh-Hans, ja, es, de, fr)
│   ├── SmartLedgerTests/            # 47 unit tests
│   ├── SmartLedgerUITests/          # 6 UI tests
│   └── TEST_VERIFICATION.md         # Detailed test report (Chinese)
├── SmartLedger/                     # HTML design prototypes (reference)
└── *.png                            # App screenshots
```

### Tech Stack / 技术栈

| Layer | Technology |
|-------|------------|
| UI | SwiftUI |
| Storage | UserDefaults (JSON-encoded expenses) |
| AI | DashScope OpenAI-compatible API (`qwen-plus`, `qwen-vl-max`) |
| IAP | StoreKit 2 |
| Speech | Speech + AVFoundation |
| Testing | XCTest + XCUITest |
| Dependencies | None (no SPM / CocoaPods — Apple frameworks only) |

> **Note:** Cloud sync and SwiftData/CloudKit are not implemented. Data is stored locally on device.

---

## Configuration / 配置说明

### API Key

| Method | Location | Notes |
|--------|----------|-------|
| Build-time bundle | `iOS/SmartLedger/Resources/LocalSecrets.plist` | Recommended for development; gitignored |
| Runtime | UserDefaults key `sl.dashscopeApiKey` | Set programmatically or via future Settings UI |

Credit costs per AI action:

| Action | Credits |
|--------|---------|
| Spending query | 2 |
| General chat | 2 |
| Text expense extraction | 5 |
| Receipt image extraction | 10 |

### Localization / 本地化

String catalogs live in `Resources/*.lproj/Localizable.strings` for **English**, **简体中文**, **日本語**, **Español**, **Deutsch**, and **Français**.

The in-app language picker offers **System**, **English**, and **简体中文**. Other locales follow the device system language automatically.

### Theme

Default primary color is mint green (`#4ADE80`). Five theme palettes are available in Settings.

---

## Testing / 测试

Run all tests from the command line:

```bash
cd iOS
xcodebuild test \
  -scheme SmartLedger \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

| Suite | Tests | Coverage |
|-------|-------|----------|
| `SmartLedgerTests` | 47 | ExpenseStore, Analytics, BailianService, Export, AppSettings, Localization, Categories, StoreKit |
| `SmartLedgerUITests` | 6 | Tab navigation, chat input, manual entry, ledger search, stats toggle, theme picker |
| **Total** | **53** | |

UI tests launch with the `UI_TESTING` argument (skips rating prompts, seeds sample data).

See [`iOS/TEST_VERIFICATION.md`](iOS/TEST_VERIFICATION.md) for a detailed feature-to-test mapping.

---

## Contributing / 贡献指南

Contributions are welcome! To get started:

1. **Fork** the repository and create a feature branch from `main`.
2. **Follow existing conventions** — SwiftUI patterns, `DesignTokens` for colors/spacing, localized strings for all user-facing text.
3. **Add or update tests** for new behavior in `SmartLedgerTests` or `SmartLedgerUITests`.
4. **Never commit secrets** — keep `LocalSecrets.plist` out of version control. Optional pre-commit hook: `cp scripts/check-secrets.sh .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit`
5. **Open a Pull Request** with a clear description of changes and test results.

Please open an issue first for large features or architectural changes.

---

## Known Limitations / 已知限制

- **Local storage only** — no iCloud sync (design placeholder exists in mockups)
- **Light mode only** — dark mode is intentionally disabled
- **Portrait orientation** — landscape is not supported
- **IAP products** — require App Store Connect configuration for production; local testing uses `Products.storekit`

---

## Acknowledgments / 致谢

- **[Alibaba Cloud Bailian / DashScope](https://www.aliyun.com/product/bailian)** — Qwen models for AI expense extraction
- **[Qwen](https://github.com/QwenLM/Qwen)** — underlying LLM and vision models
- UI design prototypes in `SmartLedger/` served as the visual reference for the SwiftUI implementation

---

## License / 许可证

This project is licensed under the [MIT License](LICENSE).

---

<p align="center">
  SmartLedger v2.4.1 · Made with SwiftUI
</p>
