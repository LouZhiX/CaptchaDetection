# actionhandler —— 指令管道（domain）

## 1. 定位

- 处理**异步下发 + 需要追踪结果**的一类请求
- 典型场景：下发扩容/重启/升级指令到远端 agent，等待结果上报

## 2. 四阶段闭环

```
 产生 ─▶  入库  ─▶  消费  ─▶  结果反馈
  ▲                                 │
  └─────── 幂等 / 重试 / 死信 ◀─────┘
```

| 阶段     | 要点                                         |
| -------- | -------------------------------------------- |
| 产生     | 业务代码调用 `actionhandler.Create(...)` 入口 |
| 入库     | 持久化 action 记录（含 id、类型、参数、状态） |
| 消费     | 消费者按类型派发到对应 handler                |
| 结果反馈 | handler 执行完回填状态；异常时进入重试/死信  |

## 3. 新增一类指令的步骤

1. 在 `pkg/actionhandler/` 中定义新的 action type 常量
2. 实现该 action type 对应的 handler（实现 actionhandler 的 Handler 接口）
3. 注册 handler 到 action dispatcher
4. 业务层通过 `actionhandler.Create(type, payload)` 发起

## 4. 给 AI 的约束

- **禁止**自己写 goroutine + channel 替代 actionhandler（会绕过持久化和重试）
- handler 必须**幂等**：消费者可能重复调度
- handler 执行耗时较长时（> 30s），考虑拆成更小粒度的 action 或走 taskcenter

## 5. 常见错误

- 把"执行逻辑"写在业务入口（应该放在 handler 里）
- 通过 action id 轮询结果（应该在 handler 完成后主动回填，业务侧订阅事件）
- 忘记处理重试：handler 里有副作用又不幂等 → 数据被重复写入
