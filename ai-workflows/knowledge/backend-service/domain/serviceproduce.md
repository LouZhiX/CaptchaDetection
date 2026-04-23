# serviceproduce —— 服务生产流程（domain）

## 1. 定位

- 各类受管服务（Hadoop / HBase / Kafka / ...）从**创建 → 部署 → 运行 → 下线**的生产流水线
- 内部大量依赖 **taskcenter**（流程驱动）+ **actionhandler**（下发指令）+ **servicelifecycle**（生命周期钩子）

## 2. 目录

```
pkg/serviceproduce/
├── *.go             # Flow / 入口
├── stage/           # Stage 定义（一组 Task）
└── task/            # Task 定义（最小执行单元）
```

## 3. 典型流程（以"创建集群"为例）

```
Flow: CreateCluster
├── Stage 1: PrepareResources
│   ├── Task: AllocateHosts
│   ├── Task: InitNetwork
│   └── Task: PrepareStorage
├── Stage 2: InstallServices   (依赖 Stage 1)
│   ├── Task: InstallHDFS
│   ├── Task: InstallYARN
│   └── Task: InstallHBase
├── Stage 3: PostCheck
│   └── Task: HealthCheck
└── Stage 4: MarkRunning
    └── Task: UpdateClusterStatus
```

## 4. Task 契约

每个 Task 必须保证：

- **幂等**（可能重复调度）
- **可重试**（暴露明确的"可重试"错误码）
- **短事务**（长耗时走 actionhandler 下发）
- **不 panic**

## 5. 给 AI 的约束

- 新增业务流程 → 先在 `docs/` 画流程图，再落代码
- 不要直接修改 Task 内部逻辑影响契约；优先**新增 Task** 或**调整 Stage 组合**
- 新 Task 必须加单测，覆盖：正常 + 重试 + 失败回滚
