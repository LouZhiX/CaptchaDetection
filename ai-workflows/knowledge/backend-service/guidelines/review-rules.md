# backend-service Code Review 规则集（L2）

> 本文件供 `agents/code-review` 使用。每一条规则的违反都应在 Review 中给出评论。
> 请先阅读 `agents/code-review/lessons/*.md`（历史教训）和 `agents/code-review/exemptions/*.md`（豁免规则）以避免误判。

---

## R1 分层纪律（Blocker）

- **R1.1** `api` 层禁止调用 `dao`
- **R1.2** `module` 层禁止直接写 SQL（即 `db.Model(...) / db.Where(...)`）
- **R1.3** `dao` 层禁止修改传入的 db（`db = db.Where(...)` 必须改为 `db = db.New().Where(...)`）
- **R1.4** `api/models`、`module/models` 禁止互相引用（通过转换函数隔离）

**如何识别**：
- 在 `pkg/api/*.go` 内 grep `dao.` / 导入 `dao` 包 → R1.1
- 在 `pkg/module/*.go` 内 grep `db.Model(` / `db.Where(` / `db.Find(` → R1.2
- 在 `pkg/dao/*.go` 内看方法是否对 `db` 参数做了非 `.New()` 派生的赋值 → R1.3

## R2 错误处理（Major）

- **R2.1** 禁止 `errors.New("...")`、`fmt.Errorf("%v", ...)` 作为业务错误返回
- **R2.2** 所有错误出口必须使用 `stackerror.New / stackerror.Wrap` 并携带 `errorcode`
- **R2.3** 面向用户的错误消息必须经过 `pkg/translation`

## R3 日志（Major）

- **R3.1** 禁止 `fmt.Println` / `log.Printf` / `println`
- **R3.2** 必须使用 `logrus`，且关键路径使用 `WithFields` 结构化
- **R3.3** 日志 level 使用合理：业务异常 `Warn` / 系统异常 `Error` / 调试 `Debug`，不要一律 `Info`

## R4 安全（Blocker）

- **R4.1** SQL 必须参数化，禁止字符串拼接（`fmt.Sprintf` 拼 SQL 属于违规）
- **R4.2** 动态 `ORDER BY` / `GROUP BY` / 表名 / 列名必须白名单校验
- **R4.3** 禁止硬编码 AK/SK、密码、token；敏感值从配置或 KMS 读取
- **R4.4** 外部输入（HTTP 参数、消息）必须校验长度、类型、枚举

## R5 并发（Major）

- **R5.1** 禁止"孤儿 goroutine"（无退出条件、无 recover）
- **R5.2** goroutine 必须 `defer recover()`（或通过 utils.GoSafe 等封装）
- **R5.3** 长时异步任务 → 走 `actionhandler`，不要 goroutine + DB 轮询

## R6 依赖（Blocker）

- **R6.1** `go.mod` 中 `internal-*` 系列不能随意升版本（必须说明原因并走 MR 讨论）
- **R6.2** 禁止引入未经安全审核的新依赖（`github.com/*` 新包需在 MR 描述里说明必要性）
- **R6.3** 禁止 `replace` 指向个人仓库

## R7 测试（Major）

- **R7.1** 新增或修改 `pkg/api` / `pkg/module` / `pkg/dao` 必须附带单测
- **R7.2** 单测必须覆盖：正常路径 + 至少 1 个异常路径
- **R7.3** dao 单测使用 sqlite / gorm-mock，**禁止直连生产库**

## R8 文档（Minor）

- **R8.1** 导出函数/方法必须有注释（第一行以标识名开头）
- **R8.2** 新增核心抽象时，同步更新 `docs/`

## R9 Context（Minor）

- **R9.1** 可能跨函数的方法第一个参数必须是 `ctx context.Context`
- **R9.2** 禁止 `context.Background()` 替代上游 ctx

## R10 命名（Minor）

- **R10.1** 包名小写，不出现下划线
- **R10.2** 错误码变量 `Err` 前缀，定义在 `pkg/errorcode`

---

## 级别说明

| 级别    | 处理建议                                       |
| ------- | ---------------------------------------------- |
| Blocker | **必须修改**，否则不可合入                     |
| Major   | 强烈建议修改，特殊情况可在 MR 描述中说明原因   |
| Minor   | 建议修改，可作为后续优化项                     |

---

## 反馈指令（第四层）

提交者可在 Agent 评论下回复以下指令：

- `/err` —— 误判（Agent 判断错误，规则不适用）
- `/miss` —— 漏报（Agent 没发现该发现的问题）
- `/ex` —— 豁免（本次场景确实特殊，规则生效但本处豁免）

Agent 会自动记录到反馈日志；负责人标记"需入库"后，自动沉淀为 `lessons.md` / `exemptions.md`。
