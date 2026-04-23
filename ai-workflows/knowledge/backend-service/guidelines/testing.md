# backend-service 测试规范（L2）

## 1. 单元测试

### 1.1 位置

- 测试文件与被测文件**同目录**、同包
- 命名：`xxx_test.go`
- 跨包测试（避免循环依赖）可放 `pkg/test/`

### 1.2 命名

```go
func TestClusterDao_GetByID(t *testing.T)       // 方法测试
func TestClusterDao_GetByID_NotFound(t *testing.T) // 特定场景
func TestGenerateToken(t *testing.T)              // 函数测试
```

### 1.3 表驱动

优先使用表驱动测试：

```go
func TestParseRange(t *testing.T) {
    cases := []struct {
        name    string
        input   string
        want    Range
        wantErr error
    }{
        {"normal", "1-10", Range{1, 10}, nil},
        {"empty", "", Range{}, errorcode.ErrInvalidRange},
        {"reverse", "10-1", Range{}, errorcode.ErrInvalidRange},
    }
    for _, c := range cases {
        t.Run(c.name, func(t *testing.T) {
            got, err := ParseRange(c.input)
            assert.Equal(t, c.want, got)
            assert.True(t, stackerror.Is(err, c.wantErr))
        })
    }
}
```

### 1.4 断言

- 推荐：`github.com/stretchr/testify/assert` 和 `require`
- `require`：失败立即 `t.Fatal`，用于"后面的断言依赖此条件"
- `assert`：失败继续执行，用于独立断言

## 2. dao 层测试

### 2.1 数据库

- **禁止连生产库**
- 推荐使用 sqlite in-memory（通过 gorm）：
  ```go
  db, _ := gorm.Open("sqlite3", ":memory:")
  db.AutoMigrate(&models.Cluster{})
  ```
- 或使用 mock：`github.com/DATA-DOG/go-sqlmock`

### 2.2 隔离

每个测试用例 **setup 自己的数据 + 结束清理**，避免测试间干扰。

## 3. module 层测试

- 依赖 dao 时用 **interface + mock**
- 避免真实连接外部服务（HBase / COS / Redis）

## 4. api 层测试

- 用 `httptest` 构造请求
- 只测试"参数校验 + 路由分发"，不测深层业务（业务在 module 层测）

## 5. 集成测试

- 位置：`pkg/test/`
- 通过 tag 控制：`//go:build integration`
- 本地运行：`go test -tags integration ./pkg/test/...`

## 6. 覆盖率目标

| 模块       | 最低覆盖率 |
| ---------- | ---------- |
| `pkg/dao`  | 70%        |
| `pkg/module` | 60%      |
| `pkg/api`  | 50%        |
| 整体       | 55%        |

## 7. 必跑命令（提交前）

```bash
go test ./pkg/...
bash checkFormat.sh
```
