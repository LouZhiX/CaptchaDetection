# Skill: mr

> 匹配场景：创建GitLab MR、生成规范的 MR 描述

## MR 描述模板

```markdown
## 背景

<为什么做 / 关联需求或 issue>

## 变更内容

- [x] 新增 xxx
- [x] 修复 xxx
- [ ] ...

## 涉及模块

- pkg/api/<xxx>
- pkg/module/<xxx>
- pkg/dao/<xxx>

## 数据库变更

- [ ] 有 → 附上 SQL 文件
- [x] 无

## 配置变更

- [ ] 有 → 说明新增键、默认值
- [x] 无

## 兼容性

- [x] 完全兼容
- [ ] 有影响 → 说明影响面与缓解

## 测试

- [x] 单元测试通过：`go test ./pkg/<xxx>/...`
- [x] 本地编译通过：`make wood`
- [ ] 集成测试
- [ ] 灰度验证

## 回滚方案

<一句话描述>

## 自检

- [x] R1 分层：api/module/dao 无越界调用
- [x] R2 错误：使用 stackerror + errorcode
- [x] R3 日志：使用 logrus，无 fmt.Println
- [x] R4 安全：SQL 参数化、无硬编码敏感信息
- [x] R7 测试：新增代码有对应单测

## Reviewer

@<reviewer1> @<reviewer2>
```

## 执行步骤

1. 读 `git log master..HEAD` 了解提交范围
2. 读 `git diff master...HEAD --stat` 了解涉及文件
3. 按模板填充（勾选实际情况）
4. 自检部分按 `knowledge/backend-service/guidelines/review-rules.md` 的 R1~R10 自查
5. 输出可直接复制到GitLab MR 的 Markdown

## 给 AI 的约束

- **不要**代替用户 push 代码
- **不要**编造 reviewer
- 自检必须**真实**查看 diff，不能凭空勾选
