#!/usr/bin/env python3
"""Git commit 确认 hook（模板）

在 Claude Code 会话中拦截 `git commit`，要求用户确认后再执行。
项目级底层检查（敏感文件扫描、commit message 规范）仍由 `.git/hooks/pre-commit` 负责。

安装：./scripts/sync.sh hooks <project>
并在 .claude/settings.json 的 PreToolUse → Bash 中注册本脚本。
"""
import json
import sys


def main() -> None:
    try:
        data = json.load(sys.stdin)
        cmd = data.get("tool_input", {}).get("command", "")
    except Exception:
        sys.exit(0)

    if "git commit" not in cmd:
        sys.exit(0)

    if "CONFIRMED=1" in cmd:
        sys.exit(0)

    result = {
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "Git commit 确认\n\n"
                "底层检查（如 gitleaks、commitlint）将在提交时由 git hook 执行。\n\n"
                "确认无误后，在命令中加入 CONFIRMED=1 再执行提交。"
            ),
        }
    }
    print(json.dumps(result, ensure_ascii=False))
    sys.exit(0)


if __name__ == "__main__":
    main()
