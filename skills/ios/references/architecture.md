# 架构与工程骨架

对齐 [playbook/ios.md](../../../playbook/ios.md) 目录约定。

## 推荐目录

```text
AppName/
├── App/
│   ├── AppNameApp.swift
│   └── AppEnvironment.swift
├── Features/
│   ├── Home/
│   │   ├── Views/HomeView.swift
│   │   ├── ViewModels/HomeViewModel.swift
│   │   └── Models/HomeItem.swift
│   └── Settings/
├── DesignSystem/
│   ├── Tokens.swift          // 间距、圆角、动画时长
│   ├── Glass.swift           // Liquid Glass + Materials 门控
│   └── Components/           // 跨 Feature 真复用组件
├── Services/
│   ├── HTTPClient.swift
│   ├── KeychainStore.swift
│   └── Endpoints.swift
└── Resources/
```

原则：

1. **按 Feature 垂直切片**，不按技术层横切所有文件
2. DesignSystem 只放「跨 Feature 真复用」；一次性 UI 留在 Feature/Views
3. 网络与密钥只出现在 Services

## 状态职责

| 状态                            | 放哪                            |
| ------------------------------- | ------------------------------- |
| 控件瞬时 UI（弹层开关、文本框） | `@State`                        |
| 父子共享 UI                     | `@Binding` / 回调               |
| 屏幕业务数据与加载态            | `@Observable` ViewModel         |
| App 级会话（登录用户）          | `@Observable` + `.environment`  |
| 磁盘偏好                        | `AppStorage` / Keychain（敏感） |

```swift
@Observable
@MainActor
final class SessionStore {
    private(set) var user: User?
    private let keychain: KeychainStore

    init(keychain: KeychainStore) {
        self.keychain = keychain
    }

    func restore() async {
        user = try? await keychain.loadUser()
    }
}
```

```swift
@main
struct AppNameApp: App {
    @State private var session = SessionStore(keychain: .live)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(session)
                .task { await session.restore() }
        }
    }
}
```

## 网络骨架

```swift
protocol HTTPClient: Sendable {
    func send<T: Decodable>(_ request: URLRequest) async throws -> T
}

struct APIError: Decodable, Error {
    let code: String
    let message: String
    let traceId: String?
}
```

- 统一 base URL（`.xcconfig` / scheme）
- 401 → SessionStore 清理 → 登录页
- 错误体尽量对齐仓库 [api-error-codes.md](../../../playbook/api-error-codes.md)

## Design Tokens（轻量）

```swift
enum AppSpace {
    static let s: CGFloat = 8
    static let m: CGFloat = 16
    static let l: CGFloat = 24
}

enum AppRadius {
    static let card: CGFloat = 16
    static let pill: CGFloat = 999
}
```

颜色优先系统语义 + Asset Catalog；不要复制一份完整「设计系统色板」除非品牌强制。

## 依赖

- **默认 SPM**（远程或 `Packages/` 本地）
- 不把 CocoaPods 写进基线；存量 Pod 项目在 `CLAUDE.md` 登记迁移意图
- 第三方 UI 库慎用：与 Liquid Glass 冲突时优先删库用系统控件

## 测试

```swift
@Test
func mapsAPIError() throws {
    let data = Data(#"{"code":"AUTH_EXPIRED","message":"…"}"#.utf8)
    let err = try JSONDecoder().decode(APIError.self, from: data)
    #expect(err.code == "AUTH_EXPIRED")
}
```

- ViewModel 可测：注入 fake `HTTPClient`
- UI 测不强制；关键支付 / 登录可用 UITest 冒烟

## CI 命令示例（GitHub Actions macOS）

```bash
xcodebuild \
  -scheme AppName \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -quiet \
  test
```

具体 scheme / destination 写在项目 `CLAUDE.md`。
