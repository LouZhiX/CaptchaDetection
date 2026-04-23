# Skill: code-review

> 触发词：`/review`、"帮我 Review 这段代码"、"审查这次 diff"
> 匹配场景：本地代码/提交前 Review、GitLab MR Review

## 目标

按 backend-service 的规则集（`knowledge/backend-service/guidelines/review-rules.md`）输出结构化 Review 意见。

## 前置加载（必须）

1. `AGENTS.md`（L0 底线规则）
2. `knowledge/backend-service/guidelines/review-rules.md`（完整规则集）
3. `agents/code-review/lessons/*.md`（历史误判教训，**高于**规则的通用判断）
4. `agents/code-review/exemptions/*.md`（已豁免规则）

## 执行步骤

### Step 1. 获取 diff

- 本地场景：`git diff --unified=10` 或 `git diff origin/main...HEAD`
- GitLab MR 场景：通过GitLab MCP 读取 MR 变更（由 `agents/code-review` 包装）

### Step 2. 识别变更范围

- 列出涉及的文件路径
- 判断命中的层：`api/` / `module/` / `dao/` / `models/` / `etc/` / 其他

### Step 3. 逐文件应用规则

对每个文件，按规则集从 **R1 → R10** 检查：

- **R1 分层**：grep 反常调用模式
- **R2 错误**：grep `errors.New` / `fmt.Errorf` / 是否缺 `errorcode`
- **R3 日志**：grep `fmt.Println` / `log.Printf`
- **R4 安全**：SQL 拼接、动态 ORDER/GROUP、硬编码敏感信息
- **R5 并发**：goroutine 是否 recover、是否有退出条件
- **R7 测试**：新增代码是否有对应 `_test.go`
- 其余按对应规则检查

### Step 4. 查询历史经验

每条发现的问题，先查 lessons：

- 若在 `lessons/*.md` 里被标记为"误判"/"已知豁免场景"，**降级或不报**
- 若在 `exemptions/*.md` 里已针对类似模式豁免，**直接忽略**

### Step 5. 输出结构化 Review

**每一条评论格式**：

```
📍 [<级别>] [<规则号>] <文件>:<行号>
  问题：<一句话描述>
  原因：<为什么违规，引用规则文件>
  建议：<给出明确的修改建议，最好附代码片段>
```

级别：`Blocker` / `Major` / `Minor`

### Step 6. 汇总

末尾给出：

```
== Review 汇总 ==
Blocker: N 条
Major:   N 条
Minor:   N 条

是否阻塞合入：YES / NO
```

## 输出约束

- 语气：**客观、具体**，不做主观评价
- 引用规则号，便于提交者追溯
- 给**可直接粘贴的修改示例**
- **不修改代码**，只输出评论
- 未确定的疑点 → 标注 `❓ 需人工确认`，不要乱报

## 错误处理

- diff 过大（>1000 行）→ 提示"建议拆分 MR"，并只对关键变更给出抽样 Review
- 无法访问文件 → 提示用户手动提供内容
- 命中 lessons 时需说明"本条建议被 lesson-XXX 降级"，便于透明

## 反馈指令（第四层闭环）

提交者回复以下指令，Agent 自动记录到反馈日志：

- `/err` —— 误判
- `/miss` —— 漏报
- `/ex` —— 豁免

> 详见 `agents/code-review/AGENT.md`
