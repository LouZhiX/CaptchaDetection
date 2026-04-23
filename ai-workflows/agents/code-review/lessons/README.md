# code-review Agent · lessons 按工程分目录

> 每个工程一个子目录，避免不同工程的误判经验互相污染。

## 目录结构

```
lessons/
├── backend-service/
│   ├── lesson-001-xxx.md
│   ├── lesson-002-xxx.md
│   └── lesson-template.md
├── <service-a>/
└── <service-b>/
```

## 加载规则

- Agent 处理某工程 MR 时，**只加载** `lessons/<该工程>/*.md`
- 不跨工程加载

## 新增 lesson

- 人工可编辑，但推荐走 Agent 自动归档流程（每日 0 点 cron）
- 文件名使用 `lesson-<编号>-<短标题>.md`
- 参考 `<工程>/lesson-template.md` 模板
