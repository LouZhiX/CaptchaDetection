# Agent: <你的 Loop Agent 名>

> 基于 `agents/loop-frame` 框架创建。
> 类型：**定时驱动 + 状态持久化**

## 1. 职责

<一句话：这个 Loop 做什么>

## 2. 触发方式

系统 crontab（见 `cron/crontab.example`）。

## 3. 执行步骤

1. load state/state.yaml → 得到 cursor
2. load config/config.yaml
3. load lessons/*.md（避免重复踩坑）
4. 按 cursor 处理一批（size = config.batch.size）
5. 每处理一个对象：
   - 正常 → 累加 total_processed
   - 异常 + 已有 lesson → 按 lesson 处理
   - 异常 + 无 lesson → 追加到 lessons/，通知人类审阅
6. 更新 state.yaml（含 last_processed_id / last_run_at）
7. 输出报告到 `state/reports/<ts>.md` + 推送企业 IM

## 4. 输入/输出

### 输入
- state.yaml
- config.yaml

### 输出
- state.yaml（更新后）
- state/reports/<ts>.md
- 企业 IM消息（简报）

## 5. 异常处理

- 连续 3 次失败 → 状态置为 `failed`，停止自动执行，仅企业 IM告警等待人工恢复
- 单次失败 → 记录 recent_errors，下次尝试

## 6. 红线

- **禁止**自动修改 knowledge/ 和 skills/
- **禁止**执行不可回滚操作（需人工确认）
