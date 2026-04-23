# backend-service 架构地图（L1）

## 1. 顶层目录

```
backend-service/
├── bin/           # 启动脚本、排障工具
├── cd/            # CI/CD 相关
├── docs/          # 设计文档
├── etc/           # 配置文件（.toml / .ini / .tmpl）
├── pkg/           # 主代码入口 ★
├── sql/           # 数据库初始化 SQL
├── tools/         # 辅助工具
├── build.sh       # 编译脚本
├── Makefile       # make wood
└── Dockerfile     # 容器化
```

## 2. 业务分层（pkg 目录）

这是 backend-service 最核心的部分，**严格遵循分层**，跨层调用会导致 Review 不通过。

```
pkg/
├── api/                 # 接入层（HTTPS） —— 只做最基本的模块组装、参数校验，少做或不做逻辑处理
│   └── models/          # 接入层入参、出参定义
├── module/              # 逻辑层（按业务模块划分） —— 禁止操作数据层（即禁止写 SQL）
│   └── models/          # 逻辑层入参、出参定义
├── models/              # 数据模型层 —— 定义 mysql/redis 等数据结构
├── dao/                 # 数据操作层 —— SQL 写在这里，禁止修改传入的 db
├── schjob/              # 接入层（定时任务）
├── serviceproduce/      # 服务生产流程（接入层-流程）
│   ├── stage/           # 流程-stage
│   └── task/            # 流程-task（注意此处文档里描述为"流程-stage"）
├── server/              # HTTP server 启动
├── main/                # 主进程入口
└── main-cmd/            # 命令行工具入口
```

## 3. 架构和工具模块

```
pkg/
├── taskcenter     # 流程驱动（引自 taskcenter-lib 依赖 + 本地扩展）
├── actionhandler  # 指令管道：指令产生 → 入库 → 消费 → 结果反馈，全流程闭环
├── servicelifecycle # 服务生命周期管理
├── serviceaction  # 服务相关 action
├── shareservice   # 共享服务
├── topology       # 拓扑
├── stackerror     # 错误码封装、定义（**统一错误处理**入口）
├── translation    # 国际化（面向用户错误消息）
├── configuration  # 配置加载
├── errorcode      # 错误码常量
├── hook           # 钩子机制
├── namespace      # 命名空间
├── usermanager    # 用户管理
└── test/          # 测试工具、测试用例
```

## 4. 调用方向

```
HTTP 请求
    │
    ▼
┌─────────┐      ┌──────────┐     ┌──────┐     ┌───────────┐
│   api   │ ───▶ │  module  │ ──▶ │ dao  │ ──▶ │  mysql    │
└─────────┘      └──────────┘     └──────┘     └───────────┘
    ▲                 │
    │                 ▼
    │            ┌──────────┐
    └────────────│ models   │  数据结构统一
                 └──────────┘

                 ┌─────────────────┐
                 │ taskcenter      │─── 驱动流程 ───▶ serviceproduce
                 └─────────────────┘
                 ┌─────────────────┐
                 │ actionhandler   │─── 异步指令闭环
                 └─────────────────┘
```

## 5. 禁止事项（与 L0 底线对应）

| 禁止                            | 原因                                              |
| ------------------------------- | ------------------------------------------------- |
| `api` 里调用 `dao`              | 违反分层，跳过了业务逻辑                          |
| `module` 里写 `db.Model(...)`   | 违反分层，SQL 应该在 `dao`                        |
| `dao` 里修改传入 db             | 会污染 session，影响其他 dao 调用                 |
| 直接 `errors.New`               | 无错误码，无堆栈，无国际化                        |
| `fmt.Println` 打日志            | 不带 level、无结构化、无 trace                    |
| 硬编码中文错误信息              | 无法国际化                                        |

## 6. 编译与运行

```bash
# 编译
make wood          # 最常用
# 或
bash build.sh
bash build-cmd.sh  # 编译 cmd 版本

# 格式检查（提交前）
bash checkFormat.sh
```

---

> 参考：`backend-service/代码规范.md`
