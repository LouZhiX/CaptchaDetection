# agent-use

> AI 工程化框架 —— 让 AI **懂规矩、随时在线、自己接活、越干越好**。

本仓库提供一套**可挂载到任意工程**的 AI 上下文工程框架，基于四层叠加架构：

1. **上下文工程**（Knowledge + Skill + Agent 三层 Git 仓库）
2. **多平台接入**（共享 `base_rule.md` + 软链到 CodeBuddy / Claude Code / Cursor）
3. **事件驱动**（Webhook + 定时任务自动触发 Agent）
4. **反馈学习**（`/err` `/miss` `/ex` 指令 → 自动沉淀 lessons / exemptions）

---

## 仓库内容

所有框架文件都在 [`ai-workflows/`](./ai-workflows/) 目录下：

| 路径 | 说明 |
|------|------|
| [`ai-workflows/README.md`](./ai-workflows/README.md) | **主文档（先看这个）** —— 完整架构、快速开始、使用场景、多工程扩展 |
| [`ai-workflows/AGENTS.md`](./ai-workflows/AGENTS.md) | 所有 AI 助手的强制入口 |
| [`ai-workflows/base_rule.md`](./ai-workflows/base_rule.md) | 跨平台唯一事实来源 |
| [`ai-workflows/knowledge/`](./ai-workflows/knowledge/) | 工程知识层（两跳定位 + L0/L1/L2 三级分层） |
| [`ai-workflows/skills/`](./ai-workflows/skills/) | Skill 执行模板（按语言分类：common / go / ...） |
| [`ai-workflows/agents/`](./ai-workflows/agents/) | Agent 角色（code-review / alert-analysis / loop-frame） |
| [`ai-workflows/webhook-server/`](./ai-workflows/webhook-server/) | 第三层事件驱动入口（骨架） |
| [`ai-workflows/cron/`](./ai-workflows/cron/) | 定时驱动配置示例 |
| [`ai-workflows/script/`](./ai-workflows/script/) | 一键安装 / 自检 / 规模体检脚本 |

---

## 快速上手

```bash
git clone https://github.com/LouZhiX/agent-use.git
cd agent-use/ai-workflows

# 1) 设置环境变量
echo 'export AI_WORKFLOWS_DIR="'"$PWD"'"' >> ~/.zshrc && source ~/.zshrc

# 2) 一键安装（软链 base_rule.md 到各 IDE 的规则目录）
bash script/install.sh

# 3) 环境自检 + 规模体检
bash script/doctor.sh
bash script/check-scale.sh
```

详细说明请看 [`ai-workflows/README.md`](./ai-workflows/README.md)。

---

## 为什么这样设计

- **把 AI 需要的一切变成 Git 仓库里的文件** —— 可 Review、可回滚、可追溯
- **两跳定位 + 按需加载** —— 工程数量增长不会让每次对话的 token 变大
- **L0 / L1 / L2 三级分层** —— L0 始终加载，L1 相对稳定，L2 按需加载
- **反馈复利** —— 每条 lesson 都在校正 Agent 判断，时间越长越准

## License

MIT
