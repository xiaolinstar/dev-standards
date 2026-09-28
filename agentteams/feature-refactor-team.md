# Feature Refactor AgentTeam Specification

定义面向复杂模块或跨项目组件重构的多 Agent 协同方案（AgentTeam）。

## 团队角色构成

| 角色                        | 职责                                                             |
| :-------------------------- | :--------------------------------------------------------------- |
| **Architect Agent**         | 分析现有代码依赖图谱，制定重构 Plan（包含接口兼容性与 ADR 决策） |
| **Coder Agent**             | 执行代码重构编辑，保持函数签名与注释完整性，消除重复与面条代码   |
| **Tester & Reviewer Agent** | 运行单元测试、类型检查、Lint 校验，并对重构代码做 Code Review    |

## 协同工作流 (Workflow)

```mermaid
sequenceDiagram
    participant User
    participant Arch as Architect Agent
    participant Coder as Coder Agent
    participant Tester as Tester & Reviewer Agent

    User->>Arch: 提出模块重构需求
    Arch->>Arch: 分析代码库并制定 implementation_plan.md
    Arch->>User: 请求 Implementation Plan 审核
    User-->>Arch: 批准重构计划
    Arch->>Coder: 交付代码重构任务
    Coder->>Coder: 执行代码变更
    Coder->>Tester: 发起自动校验与 Review
    Tester->>Tester: 跑 pnpm test, typecheck, lint
    Tester-->>Arch: 反馈校验与 Review 结果
    Arch->>User: 汇总并提交 Walkthrough 报告
```
