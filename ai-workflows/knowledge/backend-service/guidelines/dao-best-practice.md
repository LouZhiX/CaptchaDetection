# dao 层最佳实践（L2）

## 1. dao 的唯一职责

- 把业务语义的"查/增/改/删"翻译成 gorm 查询
- **不做业务判断**（如"如果 xx 则..."属于 module 层）
- **不调用其他 dao**（dao 之间横向调用，交给 module 层编排）

## 2. 禁止修改传入的 db

### ❌ 反例

```go
func (d *ClusterDao) ListByNamespace(ctx context.Context, ns string, db *gorm.DB) ([]*Cluster, error) {
    db = db.Where("namespace = ?", ns)  // ❌ 污染了外部传入的 db
    var list []*Cluster
    return list, db.Find(&list).Error
}
```

### ✅ 正例

```go
func (d *ClusterDao) ListByNamespace(ctx context.Context, ns string, db *gorm.DB) ([]*Cluster, error) {
    var list []*Cluster
    return list, db.New().Where("namespace = ?", ns).Find(&list).Error
    //            ^^^^^^ 派生 session，不污染外部
}
```

## 3. 必须参数化 SQL

### ❌ 反例（SQL 注入）

```go
db.Raw(fmt.Sprintf("SELECT * FROM t WHERE name = '%s'", name)).Scan(&list)
```

### ✅ 正例

```go
db.Raw("SELECT * FROM t WHERE name = ?", name).Scan(&list)
// 或
db.Where("name = ?", name).Find(&list)
```

## 4. 动态排序/分组需白名单

```go
var allowedOrderCols = map[string]bool{
    "id": true, "create_time": true, "update_time": true,
}

func (d *ClusterDao) List(ctx context.Context, db *gorm.DB, orderBy string) ([]*Cluster, error) {
    if !allowedOrderCols[orderBy] {
        return nil, stackerror.New(errorcode.ErrInvalidParam, "invalid orderBy: %s", orderBy)
    }
    var list []*Cluster
    return list, db.New().Order(orderBy).Find(&list).Error
}
```

## 5. namespace 默认生效

涉及资源查询时，默认加 namespace 过滤，防止越权：

```go
func (d *ClusterDao) GetByID(ctx context.Context, db *gorm.DB, id int64) (*Cluster, error) {
    ns := namespace.FromContext(ctx)  // 从 ctx 取当前命名空间
    var c Cluster
    err := db.New().Where("id = ? AND namespace = ?", id, ns).First(&c).Error
    return &c, err
}
```

## 6. RecordNotFound 的处理

gorm v1 的风格：

```go
err := db.Where("id = ?", id).First(&m).Error
if err != nil {
    if gorm.IsRecordNotFoundError(err) {
        return nil, stackerror.New(errorcode.ErrClusterNotFound, "cluster %d not found", id)
    }
    return nil, stackerror.Wrap(err, errorcode.ErrDB, "query cluster")
}
```

## 7. 事务

```go
return db.Transaction(func(tx *gorm.DB) error {
    if err := dao.Cluster.Create(ctx, tx, c); err != nil { return err }
    if err := dao.Metric.Create(ctx, tx, m); err != nil { return err }
    return nil
})
```

注意：**事务内的 dao 调用要用 tx，不是外层 db**。

## 8. 批量 + 分页

- 批量：`CreateInBatches` 或 `Save`（避免一次性插入过多）
- 分页：统一约定 `offset / limit`，限制 `limit <= 1000`

## 9. 软删除

- 数据模型 embed `gorm.Model` 自动获得 `deleted_at`
- 查已删除记录：`db.Unscoped().Find(...)`
