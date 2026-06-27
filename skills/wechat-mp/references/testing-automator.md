# E2E 测试：miniprogram-automator

> 微信官方 UI 自动化方案。文档：https://developers.weixin.qq.com/miniprogram/dev/devtools/auto/automator.html

## 安装

```bash
pnpm add -D miniprogram-automator
```

## 项目内 CLI 入口

`scripts/e2e.ts`：
```ts
import { MiniProgram } from 'miniprogram-automator';

async function main() {
  const mini = await MiniProgram.connect({
    wsEndpoint: 'ws://127.0.0.1:9420',  // 微信开发者工具的自动化端口
  });
  // ... 测试用例
  await mini.close();
}
```

## 启动微信开发者工具自动化

```bash
# macOS
/Applications/wechatwebdevtools.app/Contents/Applications/wechatwebdevtools.app/Contents/MacOS/cli \
  --auto /path/to/project \
  --auto-port 9420

# Windows
"C:\Program Files (x86)\Tencent\微信web开发者工具\cli.bat" \
  --auto "C:\path\to\project" \
  --auto-port 9420
```

CI 跑要装微信开发者工具（headless 模式支持有限，需在 Linux 用 `wine` 或自建 agent）。

## 测试用例示例

```ts
// tests/e2e/login.test.ts
import { MiniProgram } from 'miniprogram-automator';

describe('login flow', () => {
  let mini: Awaited<ReturnType<typeof MiniProgram.connect>>;

  beforeAll(async () => {
    mini = await MiniProgram.connect({ wsEndpoint: 'ws://127.0.0.1:9420' });
  });

  afterAll(async () => {
    await mini.close();
  });

  test('login with mock code', async () => {
    const page = await mini.reLaunch('/pages/login/index');
    await page.waitFor('.login-btn');
    await page.tap('.login-btn');
    await page.waitFor('/pages/home/index');
    expect(await page.path()).toBe('pages/home/index');
  });
});
```

## CI 跑 E2E

E2E 在 CI 跑稳定性差（开发者工具依赖 GUI、Mac 环境），**当前阶段（Phase 1）不强制**。可选方案：

- **Phase 2**：在 macOS runner 跑（GitHub Actions 有 macos-latest）
- **替代方案**：用 jest + 单元测试覆盖核心业务，UI 自动化只跑 smoke

```yaml
# .github/workflows/e2e.yml（macOS runner）
name: e2e
on: [workflow_dispatch]  # 手动触发，不放主流程
jobs:
  e2e:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: pnpm install --frozen-lockfile
      - run: pnpm e2e
        env:
          AUTOMATOR_WS: ws://127.0.0.1:9420
```

## 与单元测试分层

| 层 | 工具 | 跑得快 | 覆盖度 | 维护成本 |
|---|---|---|---|---|
| 单元 | Jest | ✓✓✓ | 高（services / utils） | 低 |
| 组件 | Jest + ts-jest | ✓✓ | 中（逻辑部分） | 中 |
| E2E | automator | ✗ | 低（关键路径） | 高 |

**推荐比例**：
- 70% 单元测试（services / utils / store）
- 20% 组件逻辑测试（不渲染 wxml）
- 10% E2E（核心 1-2 个流程）

## 替代品

- **`@wepy/cli`**：wepy 框架专用，**本项目不用 wepy**
- **自建 mock 后端 + jest**（推荐）：核心业务逻辑用 jest + 模拟 wx.* API 跑得更快

```ts
// __mocks__/wx.ts
export const wx = {
  getStorageSync: jest.fn(),
  setStorageSync: jest.fn(),
  request: jest.fn(),
  // ...
};
```

```ts
// services/__tests__/http.test.ts
import { http } from '../http';

jest.mock('../../miniprogram/app', () => ({ wxp: { request: jest.fn() } }));

test('http retries on 500', async () => {
  (wxp.request as jest.Mock)
    .mockRejectedValueOnce({ status: 503 })
    .mockResolvedValueOnce({ statusCode: 200, data: { ok: true } });
  const res = await http({ url: '/x' });
  expect(res).toEqual({ ok: true });
});
```
