# Agent: code-review

> 类型：**有学习能力**（AGENT.md + state/ + config/ + lessons/ + exemptions/ + feedback/）
> 触发：GitLab MR Webhook（事件驱动） + 本地 `/review` 命令

## 1. 职责

对GitLab的 MR 变更，按 `knowledge/backend-service/guidelines/review-rules.md` 执行代码审查，把评论写入 MR 代码行；同时接收提交者反馈指令，自动沉淀为 `lessons.md` / `exemptions.md`。

## 2. 触发流程

```
提交者提 MR
    │
    ▼
GitLab MR Webhook 回调 → webhook-server（本仓库 webhook-server/）
    │
    ▼
WebhookServer 解析请求 → 派发到 code-review Agent
    │
    ▼
Agent 执行：
  1. 拉取 MR 代码 diff（GitLab MCP）
  2. 加载 AGENTS.md + review-rules.md + lessons/ + exemptions/
  3. 按 Skill `code-review` 执行
  4. 调用GitLab MCP 把评论写入代码行
  5. 推送企业 IM消息（简报）
    │
    ▼
提交者回复评论：/err | /miss | /ex
    │
    ▼
Agent 记录到 feedback/ （待人工审核）
    │
    ▼
负责人标记"需入库"
    │
    ▼
Agent（每天 0 点由 cron 触发）扫描"需入库"，自动写入 lessons.md / exemptions.md
Agent 分析多条 case 是否可归纳为通用规则 → 给出建议，推送企业 IM通知（人类把关是否写入 rule）
```

## 3. 输入/输出

### 输入（从 webhook 收到）

```json
{
  "mr_id": "12345",
  "repo": "org/backend-service",
  "author": "xxx",
  "target_branch": "master",
  "source_branch": "feat/xxx"
}
```

### 输出到GitLab评论（示例）

```
📍 [Blocker] [R1.2] pkg/module/cluster/scale.go:42
  问题：module 层直接使用 db.Where(...) 写 SQL
  原因：违反分层规则（见 ai-workflows/knowledge/backend-service/guidelines/review-rules.md R1.2）
  建议：将查询下沉到 pkg/dao/cluster.go，通过 dao.Cluster.ListByStatus(ctx, db, "running") 调用。
```

### 输出到企业 IM（汇总）

```
【Code Review】MR #12345 - feat/cluster-scale-by-percent
作者：xxx
结论：Blocker 1 条，Major 2 条，Minor 3 条
详情：<GitLab MR 链接>
```

## 4. 目录结构（多工程就绪）

```
agents/code-review/
├── AGENT.md              # 本文件
├── config/
│   ├── config.yaml       # 全局默认配置（通知渠道等）
│   └── per-repo/         # ★ 每仓库一份差异化配置
│       ├── _TEMPLATE.yaml
│       └── backend-service.yaml
├── state/                # 运行状态
├── lessons/              # 按工程分目录沉淀
│   ├── README.md
│   └── backend-service/
│       └── lesson-template.md
├── exemptions/           # 按工程分目录沉淀
│   ├── README.md
│   └── backend-service/
│       └── exemption-template.md
└── feedback/             # 待审核反馈日志（按工程分）
    ├── README.md
    └── backend-service/
```

### 多工程加载规则

Agent 处理一个 MR 时：

1. 从 webhook payload 的 `repo` 字段识别工程名（如 `backend-service`）
2. 加载 `config/per-repo/<工程>.yaml`（若不存在则提示并退出）
3. 按 per-repo 配置中的 `feedback.lessons_dir` / `exemptions_dir` **只加载该工程**的经验
4. 按 per-repo 的 `rules.file` 加载对应 `knowledge/<工程>/guidelines/review-rules.md`
5. 按 `language` 字段选择 `skills/<lang>/code-review` + `skills/common/`

这保证：**不同工程的规则、经验、豁免互相隔离，不会串味**。

## 5. 反馈指令解析

| 指令   | 含义     | 处理                                                  |
| ------ | -------- | ----------------------------------------------------- |
| `/err` | 误判     | 本次评论错误，追加 `feedback/<ts>-<mr>.jsonl`（状态 pending） |
| `/miss`| 漏报     | Agent 该报而未报，同上                                |
| `/ex`  | 豁免     | 规则成立但本处特殊，同上                              |

解析示例见 `webhook-server/README.md`。

## 6. 每日 0 点沉淀任务（cron 驱动）

详见 `cron/crontab.example`。伪代码：

```
for each feedback in feedback/*.jsonl:
    if feedback.status == "need_archive":
        case = build_case(feedback)
        if feedback.type == "err" or feedback.type == "miss":
            append_to(lessons.md, case)
        elif feedback.type == "ex":
            append_to(exemptions.md, case)
        move feedback to feedback/archived/

# 多 case 聚合分析
candidates = cluster(lessons.md by similarity)
for c in candidates if c.size >= 3:
    推送企业 IM：建议新增规则 R<X>，由负责人审核后手动写入 rule.md
```

## 7. 红线

- **不得**自动修改 `knowledge/backend-service/guidelines/review-rules.md`
- **不得**自动修改 `AGENTS.md` / `base_rule.md`
- lessons / exemptions **可以**由 Agent 自动追加（append-only），**禁止删除旧条目**

## 8. 人工兜底

- 当 Agent 执行报错 3 次以上：降级为只发"待人工 Review"通知，不写入评论
- 当 diff > 1000 行：降级为抽样 Review

---

> 本 Agent 是第一层（Knowledge/Skill）+ 第三层（事件驱动）+ 第四层（反馈闭环）的完整落地样例。
