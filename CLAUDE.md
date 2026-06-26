# dev-standards

本仓库是个人开发标准的**源仓库**，不是业务项目。

## 使用方式

- 编写或修改标准时，先读 `playbook/principles.md` 和 `playbook/INDEX.md`
- 新增 Skill → 放在 `skills/<name>/`，运行 `./scripts/sync.sh skills` 同步到 `~/.claude/skills/`
- 新增 Hook 模板 → 放在 `hooks/`，用 `./scripts/sync.sh hooks <project>` 部署到目标项目
- 新增非 Claude Code adapter（如 Cursor）→ 放在 `adapters/<name>/`，用 `./scripts/sync.sh adapters <name> <project>` 部署；详见 `adapters/README.md`
- 重要决策 → `playbook/adr/` 新增 ADR，并在 INDEX 中链接

## 边界

- **放进本仓库**：跨项目通用原则、工作流、编码底线
- **不放进本仓库**：具体项目的 domain 知识（如 ai-todo CLI 细节 → 留在 ai-todo 仓库的 Skill）

## 修改基线时

- 读 `playbook/baselines/README.md` §怎么改
- 任何偏离必须新建 ADR 并在"缺口"段链上
- 跑 `bash scripts/sync.sh validate` 确认 0 违例

## 首选 Skill

新建或整理项目时，使用 `@dev-bootstrap`（同步后位于 `~/.claude/skills/dev-bootstrap`）。
