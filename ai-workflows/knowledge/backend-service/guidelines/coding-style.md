# backend-service 编码风格（L2）

## 1. 命名

| 元素        | 风格           | 示例                                   |
| ----------- | -------------- | -------------------------------------- |
| 包名        | 小写单词       | `serviceproduce`, `actionhandler`      |
| 接口        | 大驼峰 + -er   | `TaskHandler`, `ActionConsumer`        |
| 结构体      | 大驼峰         | `ClusterInfo`, `ServiceLifecycle`      |
| 方法/函数   | 大驼峰（导出）/ 小驼峰（不导出） | `GetClusterByID`, `parseParams` |
| 常量        | 大驼峰或全大写 | `DefaultTimeout`, `MAX_RETRY`          |
| 错误码变量  | `Err` 前缀     | `errorcode.ErrClusterNotFound`         |

## 2. 注释

- 所有导出标识必须有注释，第一行以标识名开头：
  ```go
  // GetClusterByID returns the cluster by id.
  // Returns ErrClusterNotFound if not exist.
  func GetClusterByID(ctx context.Context, id int64) (*Cluster, error) { ... }
  ```
- 复杂业务逻辑必须说明"为什么"，而不是"做什么"。
- 中文注释允许，但**面向接口用户的文档注释**尽量英文（利于外部协作与检索）。

## 3. 错误处理

- **禁止**：
  ```go
  return errors.New("xxx")
  return fmt.Errorf("xxx: %v", err)
  ```
- **推荐**：
  ```go
  return stackerror.New(errorcode.ErrXxx, "xxx: %v", err)
  return stackerror.Wrap(err, errorcode.ErrXxx, "context msg")
  ```
- 错误判定：
  ```go
  if stackerror.Is(err, errorcode.ErrClusterNotFound) { ... }
  ```

## 4. 日志

- **禁止 `fmt.Println`、`log.Printf`**
- 使用 logrus 结构化日志：
  ```go
  logrus.WithFields(logrus.Fields{
      "cluster_id": id,
      "op":         "scale",
  }).Info("start scaling cluster")
  ```
- Trace ID 通过 `ctx` 自动带上（若项目封装了 logger），**不要**在日志字符串里手动拼 trace_id。

## 5. Context

- 所有 **可能跨函数** 的方法签名第一个参数必须是 `ctx context.Context`
- dao 层方法：`func (d *ClusterDao) Get(ctx context.Context, id int64) (...)`
- 禁止传 `context.Background()`，**必须从上游一路透传**

## 6. 返回值

- 函数返回 error 时，error **必须是最后一个返回值**
- 不要用 `panic` 处理业务错误（panic 只用于 bug）

## 7. 并发

- goroutine 必须有明确的退出条件，不要写"孤儿 goroutine"
- 需要 goroutine 间通信时优先用 channel，次之用锁
- 涉及长时任务 → 接入 `actionhandler`，不要自己写 goroutine + DB 轮询

## 8. 格式化

- 提交前必须：
  ```bash
  gofmt -w .
  bash checkFormat.sh
  ```
- import 顺序：标准库 → 第三方 → 本项目内 `git.example.com/.../backend-service/...`

## 9. 文件大小

- 单文件建议 **不超过 500 行**。超过则按职责拆分。
- 大 struct 的方法按主题拆到不同文件（同一包内），但结构体定义本身只保留一份。
