# AGENTS.md — ai-workflows 工程入口

> **所有 AI 助手（CodeBuddy / Claude Code / Cursor / 智能体平台 / ChatGPT 等）在开始任何任务前，必须先阅读本文件。**
>
> 这是 ai-workflows 框架的唯一入口。无论使用哪个平台、哪个工具，第一件事都是读这个文件。

## 0. 定位当前工程（必做第一步）

本框架支持**挂载到多个工程**。在开始任务前，你必须先识别：

1. 当前工作区是哪个工程？（从 `pwd` / 打开文件路径 / 用户提问中判断）
2. 在 `knowledge/INDEX.md` 中查找该工程的索引入口
3. 如果**未找到匹配工程**，明确告诉用户："该工程尚未接入 ai-workflows，请先参考 `knowledge/_TEMPLATE/` 添加"，**不要**凭空套用其他工程的规则

> 如何扩展到新工程：见 `knowledge/_TEMPLATE/README.md`

---

## 1. 强制加载规则（L0 底线）

L0 分为 **全局 L0**（本文件）和 **工程 L0**（各工程 `INDEX.md` 顶部）。两者**同时生效**，工程 L0 不能覆盖全局 L0。

### 1.1 全局 L0（所有工程通用）

1. **安全基线**：
   - 涉及 SQL 的代码必须参数化，**禁止字符串拼接**
   - 动态 `ORDER BY` / `GROUP BY` / 表名/列名必须使用**白名单校验**
   - **禁止**硬编码 AK / SK / 密码 / token 到代码或配置
2. **不造数据**：涉及外部依赖时，**禁止**臆造接口、字段、返回值。先查 go.mod / godoc / 源码
3. **不擅自修改**：`AGENTS.md`、`base_rule.md`、`knowledge/**`、`skills/**` 的任何修改都需要先给出提议，经用户确认后再执行
4. **最小上下文**：**按需加载**，不要一次性读取整个 `knowledge/` 或 `skills/`
5. **反馈优先**：Review / 分析类任务，必须优先加载对应 Agent 的 `lessons/*` 和 `exemptions/*`

### 1.2 工程 L0（本工程专属，在各工程 INDEX.md 顶部）

进入具体工程后，读取 `knowledge/<工程>/INDEX.md` 的"L0 底线规则"段，作为本次任务的额外底线。

---

## 2. Knowledge 层加载声明

Knowledge 按"**两跳定位 + 三级分层**"**按需加载**，禁止一次性全部读取。

### 两跳定位（多工程可扩展）

```
第一跳: knowledge/INDEX.md              只列工程清单（一张表）
          ↓
第二跳: knowledge/<当前工程>/INDEX.md    列出本工程的 L0/L1/L2 索引
          ↓
按任务读: framework/ 或 guidelines/ 或 domain/ 下具体文件
```

无论工程从 1 个扩展到 10 个还是 100 个，**每次对话加载的内容不会因此变大**。

### 三级分层

| 级别 | 加载时机 | 内容 | 规模约束 |
|------|----------|------|----------|
| **L0** | 始终加载 | 全局 L0（本文件）+ 工程 L0（工程 INDEX 顶部） | 全局 ≤ 10 条，工程 ≤ 20 条 |
| **L1** | 了解工程结构时加载 | `framework/` 架构地图、技术栈、核心抽象 | 相对稳定，3~5 个文件 |
| **L2** | 按任务场景按需加载 | `guidelines/`（跨任务）+ `domain/`（业务领域） | 可以"很多"，靠 INDEX 定位 |

---

## 3. Skill 优先级与分类

### 声明
**ai-workflows/skills 优先级高于平台自带 Skill**。

### 分类（共享 vs 专用）

```
skills/
├── common/          # 跨工程通用（mr、design-doc、test 等）
├── go/              # Go 工程共享（code-review、coding、create-module、config）
├── cpp/             # C++ 工程共享（预留）
└── <lang>/          # 按需扩展
```

### 加载规则

1. 根据当前工程的**语言/框架**（从工程 INDEX.md 顶部读取）选择对应 `skills/<lang>/` 目录
2. `skills/common/` 永远可用
3. AI 只加载当前任务**命中的那一个** Skill，不要一次性全部加载

### 当前 Skill 清单

| 分类 | Skill | 适用场景 |
|------|-------|----------|
| `go/` | `code-review` | Go 代码审查（本地 + GitLab MR） |
| `go/` | `coding` | 通用 Go 编码（新增接口、修改 module、dao 操作） |
| `go/` | `create-module` | 从模板创建完整的 api/module/dao 三层模块 |
| `go/` | `config` | 配置修改（toml/ini） |
| `common/` | `design-doc` | 生成技术方案设计文档 |
| `common/` | `mr` | 创建 MR、生成标准 MR 描述 |
| `common/` | `test` | 生成单元测试、集成测试脚本 |

---

## 4. Agent 索引

Agent = Knowledge + Skill + MCP 外部工具 的编排，用于执行复杂/长业务流程。

| Agent | 类型 | 触发方式 | 多工程支持 |
|-------|------|----------|-----------|
| `code-review` | 带学习能力 | 事件驱动 (Webhook) | ✅ 通过 `config/per-repo/<工程>.yaml` 差异化 |
| `alert-analysis` | 带状态 | 事件驱动 (Webhook) | ✅ 通过 `config/routing.yaml` 路由 |
| `loop-frame` | 通用框架 | 定时驱动 (crontab) | ✅ 复制 TEMPLATE 为每工程独立实例 |

**Agent 的三种形态**：
- 最简：只有 `AGENT.md`
- 带状态：`AGENT.md + state/ + config/`
- 有学习能力：`AGENT.md + state/ + config/ + lessons/`

**lessons / exemptions 按工程分目录**：
```
agents/code-review/
├── lessons/
│   ├── backend-service/
│   └── <其他工程>/
└── exemptions/
    ├── backend-service/
    └── <其他工程>/
```

---

## 5. 行为约定

1. **先定位工程**：按第 0 节识别当前工程，读其 `INDEX.md`
2. **读前查索引**：修改代码前，先读相关模块的 `INDEX.md`
3. **不造轮子**：修改前先搜索相似能力
4. **不臆造接口**：依赖外部库时查 go.mod / godoc / 源码
5. **改完给命令**：在输出末尾给出验证命令（编译 / 测试 / 格式检查）
6. **反馈复用**：Review / 分析场景，必须优先加载 `lessons/<工程>/` 和 `exemptions/<工程>/`
7. **不擅改规则**：修改 `knowledge/` 或 `skills/` 前必须先征得用户同意

---

## 6. 跨平台一致性

- `base_rule.md` 是所有 IDE 和 智能体平台 智能体共享的**唯一事实来源**
- 规则迭代只改本文件和 `base_rule.md`，通过 `script/install.sh` 软链自动同步到各平台

---

## 7. 规模约束（防腐化）

为避免多工程扩展导致上下文爆炸，本仓库长期遵守：

| 约束项 | 上限 |
|--------|------|
| 全局 L0 条数（本文件 §1.1） | ≤ 10 条 |
| 单工程 L0 条数（工程 INDEX 顶部） | ≤ 20 条 |
| 单个 SKILL.md 行数 | ≤ 300 行 |
| 单个 Knowledge 文件行数 | ≤ 500 行 |
| AGENTS.md 行数 | ≤ 200 行 |

运行 `bash script/check-scale.sh` 可输出当前规模体检报告。

---

> 本文件的修改需走 MR Review，禁止直接 push。
