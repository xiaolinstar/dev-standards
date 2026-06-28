---
ID: 0008
Title: 遗留项目门禁升级时的 Lint 警告与生成数据格式规范
Status: Proposed
Date: 2026-06-28
Deciders: xingxiaolin
---

## 背景

在对已有上线项目（如 `drink-budget`）进行 `dev-standards` 标准化升级（Bootstrapping）的过程中，发现了以下两个导致 CI/CD 本地与云端门禁阻断的硬冲突：

1. **历史警告堆积与 `--max-warnings 0` 冲突**：
   - 遗留项目存在大量 `Unexpected any` 等历史 warning 警告（如 `drink-budget` 小程序中有 20 处警告）。
   - 标准门禁在 `lint-staged` 中强制执行 `eslint --max-warnings 0`。
   - 轻易使用 `eslint-disable` 注释或绕过门禁，会削弱门禁的严肃性和真实性，无法起到真正的代码质量守卫作用。

2. **自动生成数据与 Prettier 格式化冲突**：
   - 仓库内存在由特定脚本（如 `sync-drink-data.mjs`）生成的数据文件（TypeScript/JSON 格式）。
   - 自动生成的数据排版（例如数组在一行）与 Prettier 默认美化排版不一致。
   - `pre-push` 门禁会重新跑同步脚本，一旦 prettier 在 commit 时改动了数据格式，就会导致 push 时出现 diff 冲突而阻断。
   - 轻易在 `.prettierignore` 中忽略数据文件夹虽然避开了格式化冲突，但可能导致入库的数据包含脏格式。

## 议题与提案

### 议题一：遗留项目历史 warnings 门禁处理策略

#### 选项 A：绝对零容忍（强推 `--max-warnings 0` 且禁止 `eslint-disable` 逃避）
- **做法**：在升级标准时，必须由开发/审计代理同步对 20 处 `any` 警告进行类型安全重构，将 `any` 替换为正确的接口类型或 `unknown`，以彻底消除警告。
- **优点**：代码库质量得到最纯粹的提升，标准门禁不打折扣。
- **缺点**：首次补差重构工作量大，且对大范围的历史代码进行类型重构可能引入潜在的运行时回归风险。

#### 选项 B：使用过渡期警告阈值（Gradual Zero-Warning Policy）
- **做法**：在项目根目录 `package.json` 的 `lint-staged` 中，不使用 `--max-warnings 0`，而是根据当前项目警告基线设定一个特定的硬性阈值（例如 `eslint --max-warnings 20`）。在后续的迭代中，以任务卡形式将阈值逐步递减为 0。
- **优点**：避免了一次性大范围类型修改的风险，同时在 CI 阶段保持了递减的约束力。
- **缺点**：在过渡期内，容忍了部分警告的存在。

#### 选项 C：显式技术债登记（Explicit Debt Registration）
- **做法**：如果必须要用 `eslint-disable`，则必须在注释旁强制配对以 `TODO(debt):` 开头的说明，注明预计清理的里程碑或负责人。CI 流水线中加入扫描，若发现未标记 TODO 的 disable 则阻断。

---

### 议题二：自动生成数据与 Prettier 的冲突处理

#### 选项 A：生成脚本自符合格式规范（Self-Formatting Generator）
- **做法**：修改数据生成/同步脚本，在写入 JSON 或者是 TS 模块文件后，脚本在内部同步执行 `prettier --write <output-file>`，或者用代码格式化库对其进行格式化后再写入。
- **优点**：数据文件既能完美符合 Prettier 规范，又不会在重新同步时产生格式差异。
- **缺点**：增加了数据生成脚本的复杂度和运行开销。

#### 选项 B：在 `.prettierignore` 中显式忽略，并采用独立 Schema 校验
- **做法**：数据文件夹在 `.prettierignore` 中忽略以避免 prettier 格式打架，但必须在 CI 阶段运行专门的轻量数据 Schema 校验脚本（如 `validate-drink-data.mjs`）来确保数据的业务正确性。
- **优点**：解耦了排版格式与业务数据格式的冲突。
- **缺点**：数据在排版上失去了 prettier 的统一美化。

## 后果与决定

*(本段保留，等待 Decider 决定并批准具体选项)*
