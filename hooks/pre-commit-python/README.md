# Pre-commit 模板（Python 项目，使用 uv）

决策与完整说明见 [`playbook/ci-minimum-gate.md`](../../playbook/ci-minimum-gate.md)。

## 适用项目

- Flask / FastAPI / Django
- 纯 Python CLI
- 数据处理 / 机器学习项目
- 任何有 `pyproject.toml` 的项目（使用 uv 作为包管理器）

## 部署

```bash
~/AgentProjects/dev-standards/scripts/sync.sh hooks-precommit-python /path/to/project
```

写入目标项目：

| 产出 | 说明 |
|---|---|
| `.pre-commit-config.yaml` | gitleaks + ruff + uv-lock + mypy + conventional-pre-commit |

若 `.pre-commit-config.yaml` 已存在，**不覆盖**（仅 warning）。

## 安装后

```bash
cd /path/to/project

# 1. 安装 pre-commit（如未安装）
uv tool install pre-commit  # 或 uv pip install pre-commit

# 2. 安装 hooks
uv run pre-commit install
uv run pre-commit install --hook-type commit-msg

# 3. 首次运行（下载 hooks）
uv run pre-commit run --all-files
```

## 按项目调整

### mypy 依赖

在 `.pre-commit-config.yaml` 中调整 `additional_dependencies`：

```yaml
- id: mypy
  additional_dependencies: [pydantic, flask, types-requests]
```

### ruff 配置

在 `pyproject.toml` 中添加：

```toml
[tool.ruff]
line-length = 88
target-version = "py312"

[tool.ruff.lint]
select = ["E", "F", "I", "N", "W", "UP"]
```

## 与 Husky 的区别

| 命令 | 目标 | 用途 |
|---|---|---|
| `sync.sh hooks-precommit-python` | `.pre-commit-config.yaml` | Python 项目 git hooks |
| `sync.sh hooks-precommit` | `.husky/` + commitlint | Node.js 项目 git hooks |
