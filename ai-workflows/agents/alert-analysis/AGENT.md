# Agent: alert-analysis

> 类型：**带状态**（AGENT.md + state/ + config/）
> 触发：监控平台告警 Webhook

## 1. 职责

接收监控平台告警回调，结合 backend-service 的日志、代码、近期变更，定位告警根因，输出结构化分析报告并推送企业 IM。

## 2. 触发流程

```
业务服务告警 → 监控平台告警 Webhook → webhook-server → alert-analysis Agent
    │
    ├─ 1. 解析告警（服务名、指标、触发条件）
    ├─ 2. 拉取近 15 分钟日志（日志服务/内部日志平台 MCP）
    ├─ 3. 拉取相关模块的近期 commits（git log）
    ├─ 4. 结合 Knowledge 分析根因
    ├─ 5. 生成结构化报告
    └─ 6. 推送企业 IM + 打标签（P0/P1/P2）
```

## 3. 输入

```json
{
  "alert_name": "backend-service cluster create task stuck",
  "severity": "P1",
  "service": "backend-service",
  "metric": "task_stuck_count",
  "trigger_time": "2026-04-23T10:00:00Z",
  "dimensions": { "env": "pre", "cluster_id": "xxx" }
}
```

## 4. 输出（企业 IM + state 存档）

```
【告警分析】backend-service - task stuck（P1）
触发时间：2026-04-23 10:00:00

【可能根因】
1. pkg/serviceproduce/task/install_hbase.go 近 2 小时有 3 次提交（@user-xxx），改动了超时逻辑
2. 日志中大量出现 "actionhandler: dispatch timeout"（关联 pkg/actionhandler/dispatcher.go）

【建议动作】
- 人工确认：install_hbase 改动是否引入等待锁死
- 临时缓解：重启 actionhandler 消费者

【详细报告】<落地到 state/reports/2026-04-23-10-00.md>
```

## 5. 目录结构

```
agents/alert-analysis/
├── AGENT.md
├── config/
│   └── config.yaml     # 告警路由规则、通知配置
├── state/
│   ├── reports/        # 每次分析的完整报告（追加）
│   └── .gitkeep
└── prompts/
    └── analyze.md      # 分析模板（传给 LLM 的上下文）
```

## 6. 红线

- **禁止**自动重启服务（只给建议，不执行）
- **禁止**在企业 IM里贴完整日志（先存到 state/reports/，企业 IM里只贴链接）
- 超时降级：LLM 调用超时 30s → 降级为"待人工分析"并仍推送企业 IM
