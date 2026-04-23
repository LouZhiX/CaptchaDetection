# webhook-server（第三层 - 事件驱动入口）

> 事件驱动的统一入口。接收外部 webhook，派发到对应 Agent。

## 职责

| 接收                   | 派发到                 |
| ---------------------- | ---------------------- |
| GitLab MR Webhook        | `agents/code-review`   |
| 监控平台告警 Webhook       | `agents/alert-analysis`|
| 需求管理平台 Bug 单 Webhook    | （预留，未实现）       |

## 部署形态

建议作为独立进程部署（或作为 backend-service 子命令），监听 HTTP 端口，接收各平台回调。

## 路由约定（建议实现）

| 路径                  | 处理               |
| --------------------- | ------------------ |
| `POST /webhook/git`   | GitLab MR            |
| `POST /webhook/alert` | 监控平台告警           |
| `POST /webhook/需求管理平台`  | 需求管理平台（预留）       |
| `POST /webhook/feedback` | MR 评论回调（识别 /err /miss /ex） |

## 反馈指令解析（关键）

`POST /webhook/feedback` 收到 MR 评论回调时，按正则提取指令：

```
/err <可选说明>
/miss <可选说明>
/ex <可选说明>
```

解析后追加到 `agents/code-review/feedback/<ts>-mr<id>.jsonl`：

```json
{"ts":"2026-04-23T10:00:00Z","mr_id":"12345","author":"xxx","type":"err","comment_ref":"line-42-v3","note":"此处是 demo 脚本，分层检查不适用","status":"pending"}
```

## 配置

通过环境变量注入：

```bash
export AI_WORKFLOWS_DIR=/path/to/ai-workflows
export GIT_TOKEN=xxx      # GitLab MCP/API
export IM_REVIEW_WEBHOOK=https://im-bot.example.com/...
export LLM_API_KEY=xxx        # Agent 调用 LLM
```

## 实现语言建议

- Go（与 backend-service 同栈）：便于团队内部维护
- 或 Python + FastAPI：快速搭建，与 LLM 生态契合

## 当前状态

**本目录目前为骨架/说明文档**，实现代码待补充。

推荐实现路径：

1. 先写一个 Python + FastAPI 的最小可用版本
2. 接入GitLab MCP，完成一个 MR 的端到端 Review
3. 接入反馈指令解析
4. 再考虑迁移到 Go / 接 智能体平台 平台

---

> 关联：`agents/code-review/AGENT.md`、`agents/alert-analysis/AGENT.md`
