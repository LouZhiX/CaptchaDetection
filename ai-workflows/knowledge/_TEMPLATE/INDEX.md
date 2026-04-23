# <工程名> 工程索引（两跳定位 · 第二跳）

> 工程路径：`<绝对路径>`
> 模块路径：`<如 git.example.com/xxx>`
> 语言：`<go|cpp|python|...>`   框架：`<简述>`

---

## L0 底线规则（始终加载，≤ 20 条）

> ⚠️ 规则只写**最关键、违反即 Blocker** 的条目。细节规则放到 `guidelines/`。

1. <例：禁止跨层调用>
2. <例：错误处理统一用 xxx>
3. ...

---

## L1 架构地图（了解工程时加载）

- [`framework/architecture.md`](./framework/architecture.md) — 分层与目录组织
- [`framework/tech-stack.md`](./framework/tech-stack.md) — 技术栈清单
- [`framework/core-abstractions.md`](./framework/core-abstractions.md) — 核心抽象（可选）

---

## L2 指导原则（按场景加载）

- [`guidelines/coding-style.md`](./guidelines/coding-style.md) — 编码风格
- [`guidelines/review-rules.md`](./guidelines/review-rules.md) — Code Review 规则集
- [`guidelines/testing.md`](./guidelines/testing.md) — 测试规范

---

## L2 业务领域（按任务加载）

- [`domain/<领域1>.md`](./domain/<领域1>.md) — ...
- [`domain/<领域2>.md`](./domain/<领域2>.md) — ...

---

## 常见任务索引

| 任务 | 先读 | 配合 Skill |
|------|------|-----------|
| 新增接口 | framework/architecture + guidelines/coding-style | `skills/<lang>/coding` |
| 代码 Review | guidelines/review-rules + 相关 lessons | `skills/<lang>/code-review` |
| ... | ... | ... |

---

> 最后更新：YYYY-MM-DD
