# taskcenter —— 流程驱动（domain）

> 面向 AI 的精简指南。详细用法见 `taskcenter-lib` 仓库文档。

## 1. 什么时候用 taskcenter

**满足以下任一条件，就用 taskcenter**：

- 一次请求无法同步完成（需要多步异步执行）
- 步骤之间有依赖关系（A 完成后 B 才能开始）
- 单个步骤可能长达分钟/小时级
- 失败后需要从断点恢复，而不是整体重跑

典型场景：创建集群、扩/缩容、升级组件、大批量数据初始化。

## 2. 基本概念

| 概念   | 说明                                                         |
| ------ | ------------------------------------------------------------ |
| Task   | 一个最小执行单元（幂等、可重跑）                             |
| Stage  | 一组 Task 的集合，**Stage 内 Task 顺序执行或并发**           |
| Flow   | 一组 Stage 组成的完整流程（即一次业务"流程"）               |
| Driver | 驱动流程推进的核心，监听 Task 完成事件并调度下一个 Task/Stage |

## 3. 在 backend-service 里的落位

- 业务流程定义：`pkg/serviceproduce/`（如创建 集群的完整流程）
- 单个 Stage 定义：`pkg/serviceproduce/stage/`
- 单个 Task 定义：`pkg/serviceproduce/task/`

## 4. 一个新增流程的标准步骤

1. **画流程图**（先想清楚 Stage 拆分），放到 `docs/`
2. 在 `pkg/serviceproduce/task/` 中实现每个 Task（实现 taskcenter 的 Task 接口）
3. 在 `pkg/serviceproduce/stage/` 中组装 Stage
4. 在 `pkg/serviceproduce/` 中定义 Flow，注册到 driver
5. 补单测：Task 级单测 + Flow 级集成测试

## 5. 给 AI 的约束

- **不要**自己写 goroutine + channel 实现"异步 + 依赖"，直接用 taskcenter
- **不要**用 DB 状态字段做"轮询状态机"，交给 taskcenter 驱动
- Task 的 Run 方法必须**幂等**：可能被重复调度
- Task 内部**禁止 panic**（panic 会让 driver 状态混乱）
