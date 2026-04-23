# Skill: config

> 匹配场景：修改 `etc/*.toml` / `*.ini` / `*.tmpl`，新增/删除/改名配置项

## 前置加载

- `knowledge/backend-service/guidelines/config-convention.md`

## 执行步骤

### Step 1. 定位配置

```bash
grep -rn "<key_name>" etc/ pkg/configuration/ pkg/
```

输出所有使用点，确认影响面。

### Step 2. 修改

修改时**严格保留原有注释**。新增键时必须同时提供：

1. 键名（snake_case）
2. 默认值
3. **中文注释说明用途**

### Step 3. 同步 pkg/configuration

在 `pkg/configuration/` 对应结构体中新增字段：

```go
type ServerConfig struct {
    // ...
    // 新增字段，对应 server.toml 的 max_connections
    MaxConnections int `toml:"max_connections" default:"1000"`
}
```

### Step 4. 给使用点

通过 `configuration.Get().ServerConfig.MaxConnections` 访问，**禁止直接 os.Open**。

### Step 5. 编译校验

```bash
make wood
# 或
go build ./pkg/configuration/...
```

### Step 6. MR 描述

必须提供以下信息：

```
本次配置变更：
- 新增 server.toml 中 max_connections，默认 1000
- 用于限制服务端最大连接数
- 兼容性：无（新增键，缺省时用默认值）
- 线上下发计划：下个版本随代码一起发布
```

## 红线

- **禁止**硬编码密码/AK/SK/token 到 `etc/*.toml`
- **禁止**改默认值但不在 MR 描述中说明
- **禁止**删除配置项而不考虑兼容性（至少保留一个版本的双读）
