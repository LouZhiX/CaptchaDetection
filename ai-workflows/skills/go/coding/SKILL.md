# Skill: coding

> 匹配场景：修改某个 module 下的业务逻辑、新增接口、修改 dao、补充 models 字段

## 目标

在 backend-service 的分层架构约束下，帮助用户完成具体的编码任务。

## 前置加载

1. `AGENTS.md`（L0）
2. `knowledge/backend-service/framework/architecture.md`（分层）
3. `knowledge/backend-service/guidelines/coding-style.md`
4. 按任务补充：`guidelines/dao-best-practice.md` / `domain/taskcenter.md` / `domain/actionhandler.md`

## 执行流程

### Step 1. 任务澄清

- 用户描述是否明确到"改哪个文件 / 哪个方法"？如不明确，**先列出候选点，再询问**。
- 识别涉及的分层：api / module / dao / models / taskcenter / actionhandler。

### Step 2. 读现场

- 读相关文件（≤3 个）**完整内容**，不要只读节选
- grep 调用关系，确认这次改动的影响范围

### Step 3. 给出方案

先输出一个 **简短实施方案**（不写代码）：

```
方案：
1. 在 pkg/module/cluster/cluster_scale.go 新增 ScaleByPercent 方法
2. 在 pkg/api/cluster/cluster.go 新增路由 POST /cluster/:id/scale-by-percent
3. 在 pkg/dao/cluster.go 新增 UpdateCapacity 方法
4. 修改 pkg/api/models/cluster.go 新增 ScaleByPercentReq

涉及测试：
- pkg/module/cluster/cluster_scale_test.go
- pkg/dao/cluster_test.go
```

等用户确认后再落代码。

### Step 4. 编码

严格遵守 L0 + coding-style：

- **分层**：api 不写业务 / module 不写 SQL / dao 不改 db
- **错误**：`stackerror.New(errorcode.ErrXxx, ...)`
- **日志**：`logrus.WithFields`
- **Context**：一路透传
- **命名**：大驼峰/小驼峰/snake_case（配置键）

### Step 5. 补测试

按 `guidelines/testing.md`：

- 新增/修改的公开方法 → 至少 1 个正常路径 + 1 个异常路径
- dao 测试用 sqlite in-memory 或 sqlmock

### Step 6. 验证

输出给用户的末尾必须包含：

```bash
# 编译
make wood

# 测试
go test ./pkg/<改动模块>/...

# 格式
bash checkFormat.sh
```

## 红线

- **禁止**自主升级 go.mod 依赖
- **禁止**跨层调用（见 R1）
- **禁止**直接 `errors.New` / `fmt.Println`
- **禁止**修改 `AGENTS.md` / `base_rule.md` / `knowledge/`

## 产出格式

每次任务最终产出：

1. **实施方案**（Step 3 输出）
2. **代码变更**（用 diff 或完整片段，明确文件路径）
3. **测试代码**
4. **验证命令**
