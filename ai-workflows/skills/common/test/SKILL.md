# Skill: test

> 匹配场景：生成单元测试、集成测试、辅助排查

## 前置加载

- `knowledge/backend-service/guidelines/testing.md`

## 子场景

### 场景 A：为已有方法补单测

输入：`<文件路径>:<方法名>`

步骤：

1. 读方法源码，识别：入参、出参、外部依赖（dao/其他 module/外部服务）
2. 针对外部依赖使用 interface + mock
3. 生成表驱动测试，覆盖：
   - 正常路径（至少 1）
   - 参数异常（边界值）
   - 依赖异常（dao 返回 NotFound / DBError）
4. 跑一遍：`go test -run TestXxx ./pkg/<xxx>/`

### 场景 B：为 dao 方法补单测

使用 sqlite in-memory：

```go
func setupDB(t *testing.T) *gorm.DB {
    db, err := gorm.Open("sqlite3", ":memory:")
    require.NoError(t, err)
    err = db.AutoMigrate(&models.ClusterBackup{}).Error
    require.NoError(t, err)
    return db
}

func TestClusterBackupDao_Get(t *testing.T) {
    db := setupDB(t)
    dao := &ClusterBackupDao{}
    // 准备数据
    _ = db.Create(&models.ClusterBackup{Name: "test", Namespace: "ns1"}).Error
    // 执行
    ctx := namespace.WithContext(context.Background(), "ns1")
    got, err := dao.Get(ctx, db, 1)
    // 断言
    require.NoError(t, err)
    require.Equal(t, "test", got.Name)
}
```

### 场景 C：gRPC / HTTP 集成测试脚本

- 通过 `httptest.NewServer` 拉起 api 层
- 构造请求，断言响应
- 集成测试文件加 `//go:build integration` tag

### 场景 D：测试环境排障

- 生成一段 curl 命令（带 trace header）用于手动验证
- 或生成 grpcurl 命令（若是 gRPC 接口）

## 产出

- 测试文件路径明确
- 每个 case 有 `t.Run(name, ...)` 命名
- 必要时给出执行命令：

  ```bash
  go test -v ./pkg/<xxx>/ -run TestXxx
  go test -tags integration ./pkg/test/...
  ```

## 红线

- **禁止**连生产库
- **禁止**写 `time.Sleep` 做等待（用 channel 或 assert.Eventually）
- **禁止**用随机数作为测试期望值（覆盖率上去了但没意义）
