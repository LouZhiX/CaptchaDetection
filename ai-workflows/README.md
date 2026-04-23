# ai-workflows

> AI 工程化框架 —— 让 AI **懂规矩、随时在线、自己接活、越干越好**。
>
> 以 **[backend-service](~/projects/backend-service)**（Go / 后端服务）为样板落地；**多工程就绪**，可挂载到任意工程。


---

## 目录

- [TL;DR](#tldr)
- [一、四层架构](#一四层架构)
- [二、快速开始（3 分钟）](#二快速开始3-分钟)
- [三、仓库结构](#三仓库结构)
- [四、使用场景](#四使用场景)
- [五、扩展到多个工程](#五扩展到多个工程)
- [六、规模治理（防腐化）](#六规模治理防腐化)
- [七、设计原则](#七设计原则)
- [八、常见问题 FAQ](#八常见问题-faq)
- [九、更新日志](#九更新日志)

---

## TL;DR

| 你想做什么 | 怎么做 |
|---|---|
| 让 AI 遵守 backend-service 规则写代码 | 打开工程，AI 自动读 `AGENTS.md` |
| 提 MR 时自动 Code Review | GitLab Webhook → `agents/code-review`（事件驱动） |
| 接收告警自动分析根因 | 监控平台 Webhook → `agents/alert-analysis` |
| 定时扫描测试环境 | crontab → `agents/loop-frame`（Agent Loop） |
| 新增一个工程接入 | `cp -r knowledge/_TEMPLATE knowledge/<新工程>`，详见 §五 |
| 检查框架是否腐化 | `bash script/check-scale.sh` |

---

## 一、四层架构

四层**叠加**：第一层是基座，上面三层独立产生价值、叠加效果更好。

| 层 | 做了什么 | 解决的问题 | 核心手段 | 本仓库落地 |
|---|---|---|---|---|
| **第一层** | 上下文工程 | AI 不懂业务，产出不稳 | Knowledge + Skill + Agent 三层 | `knowledge/ skills/ agents/` |
| **第二层** | 多平台接入 | 能力锁在 PC IDE | 共享工作区 + 软链 base_rule.md | `base_rule.md` + `script/install.sh` |
| **第三层** | 事件驱动 | AI 依赖人触发 | Webhook + 定时任务 | `webhook-server/`（骨架）+ `cron/` |
| **第四层** | 反馈学习 | 判断偏差无法自纠 | `/err /miss /ex` 指令 → 自动沉淀 | `agents/code-review/{lessons,exemptions}/` |

---

## 二、快速开始（3 分钟）

```bash
# 1) 确认路径，设置环境变量
cd /Users/user/tsProject/agent-use/ai-workflows
echo 'export AI_WORKFLOWS_DIR="'"$PWD"'"' >> ~/.zshrc && source ~/.zshrc

# 2) 一键安装（自动软链 base_rule.md 到 CodeBuddy / Claude Code / Cursor）
bash script/install.sh

# 3) 环境自检 + 规模体检
bash script/doctor.sh
bash script/check-scale.sh

# 4) 在 IDE 打开 ~/projects/backend-service，AI 会自动读取 AGENTS.md
```

> **验收预期**：`doctor.sh` 20 ✅ / 0 ❌，`check-scale.sh` 全部通过。

---

## 三、仓库结构

```
ai-workflows/
├── AGENTS.md                    ★ 所有 AI 的强制入口
├── base_rule.md                 ★ 跨平台唯一事实来源（第二层）
├── README.md                    本文件
│
├── knowledge/                   【第一层】知识层 —— "AI 的知识宝库"
│   ├── INDEX.md                 第一跳：工程清单（纯表格，工程多也不膨胀）
│   ├── _TEMPLATE/               多工程就绪：新增工程从这里拷贝
│   └── backend-service/       第二跳：工程级知识
│       ├── INDEX.md             含工程 L0 底线 + L1/L2 索引
│       ├── framework/           L1 架构地图（相对稳定）
│       ├── guidelines/          L2 指导原则（按场景加载）
│       └── domain/              L2 业务领域（按任务加载）
│
├── skills/                      【第一层】执行模板层 —— "这类任务该怎么做"
│   ├── README.md
│   ├── common/                  跨语言通用：mr / design-doc / test
│   └── go/                      Go 工程共享：code-review / coding / create-module / config
│
├── agents/                      【第一层】角色层 —— "自主执行复杂流程"
│   ├── code-review/             带学习能力（含 §四反馈闭环）
│   │   ├── config/per-repo/     ★ 每仓库差异化配置
│   │   ├── lessons/<工程>/      ★ 按工程分目录沉淀，不串味
│   │   ├── exemptions/<工程>/
│   │   └── feedback/<工程>/
│   ├── alert-analysis/          事件驱动（告警根因定位）
│   └── loop-frame/              通用 Agent Loop 骨架（state/config/lessons）
│
├── webhook-server/              【第三层】事件驱动入口（骨架，待实现）
├── cron/                        【第三层】定时任务示例
│   └── crontab.example
│
└── script/                      【第二层】工具脚本
    ├── install.sh               软链 base_rule.md 到各 IDE
    ├── uninstall.sh
    ├── doctor.sh                环境自检
    ├── run-agent.sh             Agent 启动器（占位）
    └── check-scale.sh           ★ 上下文规模体检（防腐化）
```

---

## 四、使用场景

### 以 backend-service 为例

| 场景 | 触发方式 | 背后 Skill / Agent |
|---|---|---|
| 为 `pkg/module/xxx` 新增业务逻辑 | 直接问 AI | `skills/go/coding` |
| 从 0 创建一个 api/module/dao 三层模块 | 直接问 AI | `skills/go/create-module` |
| 修改 `etc/*.toml` 配置 | 直接问 AI | `skills/go/config` |
| 提交 MR 前本地 Review | `/review` | `skills/go/code-review` |
| 生成技术方案文档 | 直接问 AI | `skills/common/design-doc` |
| 生成 MR 描述 | 直接问 AI | `skills/common/mr` |
| 补单测 / 集成测试 | 直接问 AI | `skills/common/test` |
| GitLab MR 触发自动 Review | GitLab Webhook | `agents/code-review`（事件驱动 + 反馈闭环） |
| 监控平台告警触发自动分析 | 告警 Webhook | `agents/alert-analysis` |
| 每日扫描 Error 日志 | crontab | `agents/loop-frame` + 巡检 state |

### 反馈闭环（第四层）工作方式

```
Agent 给出 Review 评论
    │
    ▼
提交者回复  /err（误判） | /miss（漏报） | /ex（豁免）
    │
    ▼
webhook-server 解析 → 写入 agents/code-review/feedback/<工程>/
    │
    ▼
负责人标记"需入库"（只需改一个字段，几秒）
    │
    ▼
cron 每天 0 点扫描 → 自动写入 lessons/<工程>/ 或 exemptions/<工程>/
    │
    ▼
累积 ≥3 条同类 case → Agent 分析并推送"建议新增规则"（人类把关写入）
```

---

## 五、扩展到多个工程

### 核心承诺

**工程数量增长不会让每次对话的上下文变大。**

| 场景 | 单次对话加载 |
|---|---|
| 1 个工程（当前） | ≈ 500 行（AGENTS + base_rule + 当前工程 INDEX + 1 Skill + 1~2 知识文件） |
| 10 个工程 | **不变**（`knowledge/INDEX.md` 多 9 行清单而已） |
| 100 个工程 | **不变**（启用 `knowledge/domains/` 二级分片） |

当前 backend-service 的**典型 Review 任务加载估算：359 行**（不含 diff 与 lessons），由 `check-scale.sh` 自动计算。

### 新增一个工程（一键流程）

```bash
NEW=<新工程名>   # 如 service-alpha

# 1) 复制工程模板
cp -r knowledge/_TEMPLATE knowledge/$NEW

# 2) 在 knowledge/INDEX.md 的"工程清单"表格加一行

# 3) 填充 knowledge/$NEW/INDEX.md
#    - 顶部声明 language: go | cpp | python
#    - 填 L0 底线规则（≤ 20 条）
#    - 补 framework/ guidelines/ domain/ 下的必要文件

# 4) Go 工程直接复用 skills/go/；其他语言新建 skills/<lang>/

# 5) 建 Agent 侧的按工程目录 + 配置
mkdir -p agents/code-review/{lessons,exemptions,feedback}/$NEW
cp  agents/code-review/config/per-repo/_TEMPLATE.yaml \
    agents/code-review/config/per-repo/$NEW.yaml
# 编辑 $NEW.yaml：rules.file / feedback.*_dir / language / verify 等

# 6) 规模自检
bash script/check-scale.sh
```

> 详见 [`knowledge/_TEMPLATE/README.md`](./knowledge/_TEMPLATE/README.md)。

### 为什么不会爆炸

- **两跳定位**：第一跳只是工程清单，第二跳才真正进入工程知识
- **L0 分级约束**：全局 ≤ 10 条 + 工程 ≤ 20 条
- **Skill 按需加载**：50 个 Skill 也只加载命中的那 1 个
- **lessons 按工程分目录**：工程 A 的误判经验不会污染工程 B 的 Review
- **per-repo 配置**：每个工程单独声明规则引用、语言、验证命令

---

## 六、规模治理（防腐化）

### 一条命令看健康度

```bash
bash script/check-scale.sh              # 日常查看
bash script/check-scale.sh --strict     # 超限时非 0 退出（接 git pre-commit / CI）
```

### 当前约束上限（与 `AGENTS.md §7` 保持一致）

| 约束项 | 上限 | 当前值 |
|---|---|---|
| AGENTS.md 行数 | 200 | 116 ✅ |
| 全局 L0 条数（§1.1） | 10 | 5 ✅ |
| 单工程 L0 条数（工程 INDEX 顶部） | 20 | 7 ✅ |
| 单个 SKILL.md 行数 | 300 | 最大 112 ✅ |
| 单个 Knowledge 文件行数 | 500 | 最大 92 ✅ |

### 建议的防腐化动作

1. **接 git pre-commit hook**：强制 `check-scale.sh --strict` 通过
2. **新增 L0 规则先问自己**：真的每个任务都需要吗？不是的话下沉到 guidelines/
3. **lessons/exemptions 只能追加不能删**：Agent 自动归档，人工 Review 前不动旧条目
4. **knowledge 每超过 500 行拆分**：按子主题分文件，INDEX.md 做索引

---

## 七、设计原则

1. **把 AI 需要的一切变成 Git 仓库里的文件** —— 可 Review、可回滚、可追溯
2. **AGENTS.md 是唯一入口** —— 跨平台、跨工具行为一致的关键
3. **两跳定位，按需加载** —— INDEX → 工程 INDEX → 具体文件，不污染上下文
4. **L0 / L1 / L2 三级分层** —— L0 始终加载，L1 了解结构时加载，L2 按任务加载
5. **单向依赖** —— Knowledge → Skill → Agent，下层不感知上层
6. **先跑起来，再慢慢优化** —— 需求驱动，不是设计驱动
7. **多工程不爆炸** —— 仓库可以大，对话上下文不能大
8. **反馈复利** —— 每条 lesson 都在校正 Agent 判断，时间越长越准

---

## 八、常见问题 FAQ

**Q1：`skills/go/code-review` 和 `agents/code-review/` 有什么区别？**

- **Skill** = 静态模板（"这类任务该怎么做"），被动加载
- **Agent** = 执行角色（"主动接活 + 持有状态 + 学习"），事件/定时驱动

Agent 在执行时会**内部加载**对应的 Skill 作为能力来源。

---

**Q2：工程 L0 和全局 L0 冲突了怎么办？**

全局 L0 是**底线**，工程 L0 不能放松只能加严。发生冲突时以全局为准。

---

**Q3：Agent 自动修改了 `knowledge/` 或 `skills/` 吗？**

**不会**。AGENTS.md §5.5 明确禁止 Agent 擅自修改规则。Agent **只能追加** `lessons/` 和 `exemptions/`（append-only），且修改 `rule.md` 永远需要人类最终审核。

---

**Q4：webhook-server 当前是空的？**

是的，仓库现在落的是**骨架和规范**（见 `webhook-server/README.md`）。推荐实现路径：

1. Python + FastAPI 最小版
2. 接入GitLab MCP 打通一个 MR 的端到端 Review
3. 接入 `/err /miss /ex` 指令解析
4. 再看是否迁到 Go 或对接 智能体平台 平台

---

**Q5：如何在没有 backend-service 的机器上使用？**

1. 把本仓库和目标工程放在同一工作区
2. 确保 `AI_WORKFLOWS_DIR` 环境变量正确
3. 跑 `install.sh` 软链 base_rule.md
4. 如果目标工程不是 backend-service，按 §五新增工程

---

## 九、更新日志

### 2026-04-23 · v1.1 多工程就绪升级

**目标**：工程数量增长不会让每次对话的上下文变大。

**改造清单**：

| 模块 | 改动 |
|---|---|
| **AGENTS.md** | 去单工程硬绑定；新增"动态定位当前工程"流程；L0 拆分为"全局 ≤10 + 工程 ≤20"；新增规模约束章节 |
| **knowledge/** | `INDEX.md` 改为纯清单；新增 `_TEMPLATE/` 工程模板 |
| **skills/** | 按语言分类：`common/` + `go/`（+ 未来 `cpp/` `python/`） |
| **agents/code-review/** | 新增 `config/per-repo/`；`lessons/exemptions/feedback/` 按工程分子目录 |
| **script/check-scale.sh**（新增） | 上下文规模体检报告，支持 `--strict` 接 CI |

**量化结果**：

```
doctor.sh        20 ✅  / 3 ⚠️（平台软链未执行）/ 0 ❌
check-scale.sh   体检全部通过
AGENTS.md        116 / 200 行
全局 L0          5 / 10 条
典型 Review 加载  359 行（不含 diff 与 lessons）
```

### 2026-04-23 · v1.0 初始版本

按四层架构搭建完整骨架：

- **第一层**：AGENTS.md + knowledge + skills + agents
- **第二层**：base_rule.md + install.sh 软链
- **第三层**：webhook-server 骨架 + crontab 示例
- **第四层**：code-review Agent 的 `/err /miss /ex` 闭环

---

> 本框架的四层架构设计借鉴业界工程化实践：上下文工程 + 多平台接入 + 事件驱动 + 反馈学习闭环。
