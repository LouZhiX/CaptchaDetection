# Agent: loop-frame（通用 Agent Loop 框架）

> 类型：**有学习能力**（可复用骨架）
> 触发：系统 crontab（定时驱动）
>
> 解决的问题：**长时任务，跨会话状态持久化**

## 1. 核心设计："Agent 即文件系统"

用三个文件替代平台状态：

| 文件                | 用途                                                 |
| ------------------- | ---------------------------------------------------- |
| `state/state.yaml`  | 进度（到哪步、处理过哪些对象、下次从哪开始）         |
| `config/config.yaml`| 行为（批次大小、每次跑多久、过滤条件）               |
| `lessons/*.md`      | 经验（上次遇到什么坑，下次怎么避开）                 |

Agent 每次唤醒后：

```
load(state) → load(config) → load(lessons)
    │
    ▼
按 state 从断点继续
    │
    ▼
处理 config.batch_size 个对象
    │
    ├─ 遇到已知 lesson → 按 lesson 处理
    └─ 遇到新问题 → 追加 lessons/，下次避开
    │
    ▼
update(state) → 持久化进度 → 退出
```

## 2. 骨架目录

```
agents/loop-frame/
├── AGENT.md         # 本文件（通用骨架说明）
├── TEMPLATE/        # 新建具体 Loop Agent 时拷贝的模板
│   ├── AGENT.md
│   ├── config/config.yaml
│   ├── state/state.yaml.example
│   └── lessons/
│       └── .gitkeep
└── examples/
    └── test-env-inspector.md   # 示例：测试环境巡检员
```

## 3. state.yaml 示例

```yaml
version: 1
cursor:
  last_processed_id: 1234           # 上次处理到的最后一个 ID
  last_run_at: 2026-04-23T10:00:00Z
  total_processed: 567
status: running                     # running / idle / paused / failed
recent_errors:
  - at: 2026-04-23T09:00:00Z
    type: timeout
    detail: "xxx"
```

## 4. config.yaml 示例

```yaml
batch:
  size: 50                # 每次处理多少个
  max_duration_seconds: 120 # 最多跑多久
filter:
  env: pre
  service: backend-service
notify:
  im_webhook: "${IM_LOOP_WEBHOOK}"
```

## 5. 何时适合用 Loop

- ✅ 适合：**长期固定步骤 + 结果明确**
  - 测试环境巡检：每小时扫描 Error 日志
  - 定时数据归档：每天凌晨归档上一天的审计日志
  - 周期性健康检查：每 10 分钟探测外部依赖可用性

- ❌ 不适合：**复杂业务逻辑 + 无明确步骤**
  - 复杂代码重构（参考某复杂 C++ 服务 重构的 bad case）
  - 需要频繁人工判断的任务

## 6. 如何创建一个具体 Loop Agent

```bash
cp -r agents/loop-frame/TEMPLATE agents/<你的Agent名>
# 编辑 AGENT.md / config.yaml
# 在 cron/crontab.example 添加一行
```

## 7. 红线

- **禁止**在 Loop 里做"不可回滚"的变更（数据库 update/delete 类要双重确认）
- **禁止**让 Loop 自己修改 `knowledge/` 或 `skills/`
- 每次跑的**产出必须人类可见**（落 report 文件 + 企业 IM通知）
