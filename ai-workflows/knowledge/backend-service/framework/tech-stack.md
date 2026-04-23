# backend-service 技术栈（L1）

> 来源：`go.mod`（截止 2026-04-23）

## 1. 语言 & 构建

| 项         | 选择           |
| ---------- | -------------- |
| 语言       | Go 1.18+       |
| 模块管理   | Go Modules     |
| 构建       | `make wood` / `build.sh` |
| 私有依赖   | `git.example.com/*` |

## 2. Web & RPC

| 能力           | 依赖                         |
| -------------- | ---------------------------- |
| HTTP Web 框架  | `gin`（间接，通过 common-lib） |
| 参数校验       | `github.com/asaskevich/govalidator` |
| JSON           | `encoding/json` + `github.com/modern-go/reflect2` |

## 3. 数据层

| 能力     | 依赖                            | 说明                           |
| -------- | ------------------------------- | ------------------------------ |
| MySQL    | `github.com/jinzhu/gorm` v1.9.8 | **注意是 v1 版 gorm**，不是 v2 |
| Redis v6 | `github.com/go-redis/redis` v6  | 旧版                            |
| Redis v8 | `github.com/go-redis/redis/v8`  | 新版，新代码优先用             |
| HBase    | `git.example.com/.../gohbase`       | HBase SDK                 |
| COS      | `github.com/s3-go-sdk` |                           |

⚠️ **gorm v1 的 API 和 v2 差别很大**（例如 `db.Where(...).Find(...)` 返回值、`RecordNotFound()` 等），AI 生成代码时不要混用。

## 4. 工具库

| 能力         | 依赖                              |
| ------------ | --------------------------------- |
| 日志         | `github.com/sirupsen/logrus` v1.9 |
| UUID         | `github.com/google/uuid`          |
| 错误堆栈     | `github.com/pkg/errors`           |
| 十进制数值   | `github.com/shopspring/decimal`   |
| 集合         | `github.com/chenhg5/collection`   |
| 模板渲染     | `github.com/flosch/pongo2`        |
| JS 执行      | `goja` / `otto`（脚本引擎）        |
| 可观测性     | `go.opentelemetry.io/otel` v1.8   |
| 原子操作     | `go.uber.org/atomic`              |
| 命令行       | `github.com/urfave/cli` v1        |
| 协程         | `github.com/timandy/routine`      |

## 5. 业务框架（内部）

| 能力                 | 依赖                                                  |
| -------------------- | ----------------------------------------------------- |
| 公共工具             | `git.example.com/.../common-lib` v1.19.x           |
| 云服务对接           | `git.example.com/.../cloud-service` v1.2.x     |
| 流程驱动             | `git.example.com/.../taskcenter-lib` v1.2.x        |
| 安全模块             | `git.example.com/security-sdk/golang/security-module` |

## 6. 使用建议（给 AI）

- **日志**：优先使用 logrus 的结构化方式（`logrus.WithFields(...).Info(...)`）。
- **错误**：用 `pkg/stackerror` 包装，保留堆栈。
- **依赖**：不要直接 `go get` 新依赖，先在 Review 中讨论必要性。
- **Gorm**：v1 风格，查询示例：
  ```go
  if err := db.Where("id = ?", id).First(&m).Error; err != nil {
      if gorm.IsRecordNotFoundError(err) { ... }
  }
  ```
- **Redis**：新代码优先 `go-redis/v8`，老代码保留 v6。
