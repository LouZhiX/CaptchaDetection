# code-review Agent · exemptions 按工程分目录

> 每个工程一个子目录，豁免规则不跨工程共享（因为工程约束不同）。

## 目录结构

```
exemptions/
├── backend-service/
│   ├── exemption-001-xxx.md
│   └── exemption-template.md
├── <service-a>/
└── <service-b>/
```

## 加载规则

- Agent 处理某工程 MR 时，**只加载** `exemptions/<该工程>/*.md`
- 不跨工程加载

## 新增 exemption

- 优先走反馈指令 `/ex` → Agent 自动归档
- 人工新增需在 MR Review 中说明豁免理由
