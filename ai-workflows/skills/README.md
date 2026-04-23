# Skills 分类

Skills 按**语言/领域**分类存放，支持多工程共享 + 差异化。

## 目录结构

```
skills/
├── common/     # 跨语言通用（mr / design-doc / test 等文档与流程类）
├── go/         # Go 工程共享（code-review / coding / create-module / config）
├── cpp/        # C++ 工程共享（按需添加）
├── python/     # Python 工程共享（按需添加）
└── <lang>/     # 其他语言
```

## 加载规则

1. AI 从工程 `INDEX.md` 顶部读取 `language` 字段（如 `go`）
2. 仅加载 `skills/<lang>/` 和 `skills/common/` 下的 Skill
3. 同一任务命中多个 Skill 时：
   - **工程专属** > **语言共享** > **common**
   - 例：`skills/go/code-review` 会**覆盖** `skills/common/code-review`（如果后者存在）

## 新增 Skill 的检查清单

- [ ] 明确分类：是通用（common）还是语言专属（go/cpp/...）
- [ ] SKILL.md 结构完整：`目标 / 前置加载 / 执行步骤 / 输出约束 / 红线`
- [ ] 单个 SKILL.md **不超过 300 行**
- [ ] 与已有 Skill 无职责重叠

## 当前 Skill 清单

### common/

| Skill | 说明 |
|-------|------|
| `mr` | 创建 MR、生成标准描述 |
| `design-doc` | 技术方案设计文档 |
| `test` | 单元 / 集成测试生成 |

### go/

| Skill | 说明 |
|-------|------|
| `code-review` | Go 代码审查（本地 + GitLab MR） |
| `coding` | 通用 Go 编码 |
| `create-module` | 从模板创建 api/module/dao 三层模块 |
| `config` | 配置修改（toml/ini） |
