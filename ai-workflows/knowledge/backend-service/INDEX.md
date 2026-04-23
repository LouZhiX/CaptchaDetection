# backend-service 工程索引（两跳定位 - 第二跳）

> 工程路径：`~/projects/backend-service`
> 模块路径：`git.example.com/org/backend-service`
> **language: go**（Go 1.18+）  ·  **skills**: `skills/go/` + `skills/common/`

---

## L0 底线规则（始终加载）

以下规则无论做任何任务都必须遵守：

1. **禁止跨层调用**
   - `api` 层只做参数校验 + 模块组装，**不写业务逻辑**
   - `module` 层**禁止直接写 SQL**，必须调用 `dao`
   - `dao` 层**禁止修改传入的 db**，必须使用 `.New()` 派生 session
2. **错误处理统一用 `pkg/stackerror`**，禁止直接 `errors.New` / `fmt.Errorf`。
3. **日志统一用 `logrus`**（见 go.mod），禁止 `fmt.Println` / `log.Printf`。
4. **面向用户的错误信息必须接入 `pkg/translation`**（国际化）。
5. **安全**：
   - SQL 必须参数化（gorm `?` 占位符），禁止字符串拼接
   - 动态 `ORDER BY` / `GROUP BY` / 表名列名 → 白名单校验
   - 禁止硬编码 AK/SK、密码等敏感信息
6. **任何对 `pkg/api` / `pkg/module` / `pkg/dao` 的新增或修改，必须附带单元测试**。
7. **不擅自升级依赖**：`go.mod` 的外部依赖（尤其 `internal-*` 系列）不要随意升版本。

---

## L1 架构地图（了解工程时加载）

- [`framework/architecture.md`](./framework/architecture.md) — **分层架构与目录组织**（api/module/dao/models/...）
- [`framework/tech-stack.md`](./framework/tech-stack.md) — **技术栈清单**（gorm / redis / gin / otel / ...）
- [`framework/core-abstractions.md`](./framework/core-abstractions.md) — **核心抽象**（taskcenter / actionhandler / servicelifecycle 等）

---

## L2 指导原则（按场景加载）

- [`guidelines/coding-style.md`](./guidelines/coding-style.md) — 编码风格（命名、注释、错误处理）
- [`guidelines/review-rules.md`](./guidelines/review-rules.md) — Code Review 规则集（给 Agent 使用）
- [`guidelines/testing.md`](./guidelines/testing.md) — 测试规范（单元测试、集成测试）
- [`guidelines/dao-best-practice.md`](./guidelines/dao-best-practice.md) — dao 层最佳实践
- [`guidelines/config-convention.md`](./guidelines/config-convention.md) — 配置文件规范（`etc/*.toml`）

---

## L2 业务领域（按任务加载）

- [`domain/taskcenter.md`](./domain/taskcenter.md) — 流程驱动（taskcenter）
- [`domain/actionhandler.md`](./domain/actionhandler.md) — 指令管道（actionhandler）
- [`domain/serviceproduce.md`](./domain/serviceproduce.md) — 服务生产流程

> domain 下按需补充，新增知识时同步更新本索引。

---

## 常见任务索引

| 如果你要做...                     | 先读                                                    | 配合 Skill                         |
| --------------------------------- | ------------------------------------------------------- | ---------------------------------- |
| 新增一个 api 接口                 | framework/architecture + guidelines/coding-style        | `skills/coding`                    |
| 新增一整套 api/module/dao 模块    | framework/architecture + framework/core-abstractions    | `skills/create-module`             |
| 修改配置文件                      | guidelines/config-convention                            | `skills/config`                    |
| 写单元测试                        | guidelines/testing + guidelines/dao-best-practice       | `skills/test`                      |
| 代码 Review                       | guidelines/review-rules（+ agent 下 lessons/exemptions） | `skills/code-review`               |
| 理解/修改流程驱动（taskcenter）   | domain/taskcenter + framework/core-abstractions         | `skills/coding`                    |

---

> 最后更新：2026-04-23
