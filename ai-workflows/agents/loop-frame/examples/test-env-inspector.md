# 示例 Loop Agent：测试环境巡检员

> 定时扫描 **backend-service 测试环境**日志，分析潜在 bug，输出报告。

## 职责

- 扫描过去 1 小时的 Error / Panic 日志
- 按堆栈聚合、分类
- 识别新增异常（之前没出现过的）→ 重点标注
- 输出巡检报告 + 企业 IM通知

## 如何创建

```bash
cp -r agents/loop-frame/TEMPLATE agents/test-env-inspector
# 编辑 AGENT.md
# 配置 config/config.yaml（日志平台 token、关键字）
# 在 cron/crontab.example 添加：
# 0 * * * *  /path/to/run-agent.sh test-env-inspector
```

## state.yaml（运行一段时间后）

```yaml
version: 1
cursor:
  last_processed_id: "log-1745399100-abcd"
  last_run_at: 2026-04-23T10:00:00Z
  total_processed: 12450
status: running
known_errors:     # 已知异常（不再报警）
  - pattern: "timeout calling cos"
    first_seen: 2026-04-20T00:00:00Z
    count: 234
```

## 报告示例（落 state/reports/）

```
# 测试环境巡检报告 - 2026-04-23 10:00

## 概要
扫描时间：2026-04-23 09:00 ~ 10:00
总日志条数：12450
Error 条数：23
Panic 条数：0

## 新增异常（需关注）
1. [NEW] `pkg/module/cluster/scale.go:42` - 空指针 dereference (3 次)
   - trace id: 9a8b7c6d5e4f
   - 首次出现：10:15:32
   - 建议：人工确认 pkg/module/cluster/scale.go 最近提交

## 已知异常（趋势）
1. `timeout calling cos` - 234 次（近 3 天持续，建议关注 cos 服务稳定性）
```

## 红线

- 只**读日志**，不触发任何线上操作
- 新增异常先通知人类，**不自动创建 需求管理平台 单**（除非显式在 config 中开启）
