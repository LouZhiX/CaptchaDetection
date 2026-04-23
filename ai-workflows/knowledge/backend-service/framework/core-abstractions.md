# backend-service 核心抽象（L1）

## 1. taskcenter —— 流程驱动

- **职责**：把一个"用户发起的请求"拆分成一系列**可异步执行的 Stage / Task**，按 DAG 驱动。
- **典型场景**：创建一个 集群、扩容一个服务、升级一个组件 —— 单次请求无法同步完成，需要跨多步、跨服务。
- **代码位置**：
  - 外部依赖：`git.example.com/.../taskcenter-lib`
  - 本地编排：`pkg/serviceproduce/`、`pkg/serviceproduce/stage/`、`pkg/serviceproduce/task/`
- **给 AI 的提示**：
  - 新增流程 → 不要从 0 写调度，**复用 taskcenter 的 Stage/Task 抽象**
  - 状态流转通过 taskcenter 事件，不要自己再建一套状态机

## 2. actionhandler —— 指令管道

- **职责**：封装"产生指令 → 入库 → 消费 → 结果反馈"的全流程闭环。
- **典型场景**：需要下发到远端执行的命令（扩容、重启、重建等），异步并且可追踪。
- **代码位置**：`pkg/actionhandler/`
- **关键能力**：
  - 指令持久化（入库后可重放）
  - 幂等消费
  - 结果回填（通过 action id 追踪）
- **给 AI 的提示**：
  - 任何"异步下发 + 需要跟踪结果"的场景，**必须走 actionhandler**，不要自己写 goroutine + channel。

## 3. servicelifecycle —— 服务生命周期

- **职责**：管理一个被管控服务（如 里的 Hadoop / HBase）从**创建 → 部署 → 运行 → 下线**的全生命周期。
- **代码位置**：`pkg/servicelifecycle/`
- **给 AI 的提示**：
  - 新增一类受管服务 → 先读本模块，搞清楚生命周期钩子
  - 不要绕过 servicelifecycle 直接操作 服务状态字段

## 4. stackerror —— 统一错误处理

- **职责**：统一错误码、错误信息、堆栈、国际化入口。
- **代码位置**：`pkg/stackerror/` + `pkg/errorcode/` + `pkg/translation/`
- **正确用法**：
  ```go
  return stackerror.New(errorcode.ErrXxx, "param invalid: %v", param)
  ```
- **错误用法**：
  ```go
  // ❌ 无错误码
  return errors.New("param invalid")
  // ❌ 无堆栈，无国际化
  return fmt.Errorf("param invalid: %v", param)
  ```

## 5. hook —— 钩子机制

- **职责**：在流程关键节点注入自定义逻辑，避免在核心代码上打补丁。
- **代码位置**：`pkg/hook/`
- **给 AI 的提示**：
  - 需要"插入一段逻辑但又不改核心路径"时，优先考虑 hook
  - 如果找不到合适的 hook 点，先在 MR 描述中说明，再讨论是否加新的 hook

## 6. shareservice —— 共享服务

- **职责**：跨业务模块共享的能力（例如租户信息、配额、权限等）
- **给 AI 的提示**：
  - 多个 module 需要相同能力时，**沉淀到 shareservice**，不要各自写一份

## 7. namespace —— 命名空间

- **职责**：资源隔离（租户 / 项目 / 环境）
- **给 AI 的提示**：
  - 任何涉及资源查询的 dao 方法，默认要接入 namespace 过滤，防止数据越权

## 8. topology —— 拓扑

- **职责**：机器 / 节点 / 集群拓扑信息的维护
- **代码位置**：`pkg/topology/`

---

## 关系图

```
┌──────────────────────────────────────────────────────┐
│                     api                              │
└──────┬───────────────────────────────────────────────┘
       ▼
┌──────────────────────────────────────────────────────┐
│                    module                            │
│     ┌────────────┐   ┌────────────┐                  │
│     │ shareservice│   │ usermanager│                 │
│     └────────────┘   └────────────┘                  │
└──────┬───────────────────────────────────────────────┘
       ▼
┌──────────────────────────────────────────────────────┐
│                     dao                              │
└──────────────────────────────────────────────────────┘

异步侧：
  taskcenter ──驱动──▶ serviceproduce(stage/task)
  actionhandler ─异步指令闭环

横切：
  stackerror + errorcode + translation  （错误/国际化）
  hook                                   （钩子）
  topology + namespace                   （隔离/拓扑）
```
