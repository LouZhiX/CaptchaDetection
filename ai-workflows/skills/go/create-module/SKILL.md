# Skill: create-module

> 匹配场景：从 0 创建一个完整的业务模块（api + module + dao + models + test）

## 目标

在 backend-service 中按分层规范，一次性搭好一个新业务模块的骨架。

## 前置加载

- `knowledge/backend-service/framework/architecture.md`
- `knowledge/backend-service/guidelines/coding-style.md`
- `knowledge/backend-service/guidelines/dao-best-practice.md`
- `knowledge/backend-service/guidelines/testing.md`

## 输入参数（向用户收集）

| 参数          | 说明                                              |
| ------------- | ------------------------------------------------- |
| `module_name` | 模块名（snake_case，如 `cluster_backup`）         |
| `entity`      | 核心领域实体（大驼峰，如 `ClusterBackup`）        |
| `operations`  | CRUD 操作集（默认全开：List / Get / Create / Update / Delete） |
| `route_prefix`| HTTP 路由前缀（默认 `/api/v1/<module_name>`）     |
| `table_name`  | MySQL 表名（默认 `<module_name>`）                |

缺失时**先询问再动手**。

## 产出结构

```
pkg/
├── api/<module_name>/
│   ├── router.go                    # 路由注册
│   ├── <module_name>.go             # handler（只做参数校验 + 调 module）
│   └── <module_name>_test.go
├── api/models/<module_name>.go      # 接入层入参/出参
│
├── module/<module_name>/
│   ├── <module_name>.go             # 业务逻辑（入口：XxxModule）
│   ├── <module_name>_impl.go
│   └── <module_name>_test.go
├── module/models/<module_name>.go   # 逻辑层入参/出参
│
├── models/<entity>.go               # gorm 数据模型
│
├── dao/<module_name>.go             # dao（gorm 查询）
└── dao/<module_name>_test.go

sql/
└── <n>_<module_name>.sql            # 初始化 SQL（建表语句）
```

## 生成规范

### models（数据层）

```go
package models

import "github.com/jinzhu/gorm"

type ClusterBackup struct {
    gorm.Model
    Name      string `gorm:"column:name;type:varchar(128);index"`
    Namespace string `gorm:"column:namespace;type:varchar(64);index"`
    Status    string `gorm:"column:status;type:varchar(32)"`
    // ... 领域字段
}

func (ClusterBackup) TableName() string { return "cluster_backup" }
```

### dao 层

```go
package dao

type ClusterBackupDao struct{}

func (d *ClusterBackupDao) Get(ctx context.Context, db *gorm.DB, id int64) (*models.ClusterBackup, error) {
    ns := namespace.FromContext(ctx)
    var m models.ClusterBackup
    err := db.New().Where("id = ? AND namespace = ?", id, ns).First(&m).Error
    if err != nil {
        if gorm.IsRecordNotFoundError(err) {
            return nil, stackerror.New(errorcode.ErrClusterBackupNotFound, "cluster backup %d not found", id)
        }
        return nil, stackerror.Wrap(err, errorcode.ErrDB, "get cluster backup")
    }
    return &m, nil
}
// ...List / Create / Update / Delete
```

### module 层

- 禁止出现 `db.Where/Find/Model/Save`
- 通过 `dao.<Xxx>` 暴露的方法访问数据
- 业务校验（跨实体一致性、状态流转规则）在此层

### api 层

- 仅做参数绑定 + 校验 + 调用 module
- 返回统一格式：`{code, msg, data}`（项目既有约定）

### SQL

```sql
-- sql/999_cluster_backup.sql
CREATE TABLE IF NOT EXISTS `cluster_backup` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `deleted_at` datetime DEFAULT NULL,
  `name` varchar(128) DEFAULT NULL,
  `namespace` varchar(64) DEFAULT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_name` (`name`),
  KEY `idx_namespace` (`namespace`),
  KEY `idx_deleted_at` (`deleted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

### 错误码

- 在 `pkg/errorcode/` 新增常量（按既有风格）：`ErrClusterBackupNotFound`
- 在 `pkg/translation/` 对应位置增加中英文翻译

## 执行顺序

1. 与用户确认输入参数
2. 在 `docs/` 新增设计稿（可选，用 `skills/design-doc`）
3. 生成 SQL + models
4. 生成 dao + 单测
5. 生成 module + 单测
6. 生成 api + 路由注册 + 单测
7. 生成错误码 + translation
8. 输出 `make wood` + `go test ./pkg/...` 命令供验证

## 红线

- **禁止**跨模块直接 import（`module/cluster_backup` 不要 import `module/cluster`，应通过 shareservice 或业务编排）
- **禁止**在 models 里写业务方法（models 只是数据结构）
- **禁止**跳过 namespace 过滤
