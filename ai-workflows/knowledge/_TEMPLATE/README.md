# 如何新增一个工程到 ai-workflows

> 本目录是"新增工程"的模板。请**拷贝本目录**为新工程名，而不是直接修改本目录。

## 一、步骤

```bash
# 1. 假设新工程名叫 service-alpha（snake-case）
AI_WORKFLOWS_DIR=/path/to/ai-workflows
NEW=service-alpha

# 2. 复制模板
cp -r "$AI_WORKFLOWS_DIR/knowledge/_TEMPLATE" "$AI_WORKFLOWS_DIR/knowledge/$NEW"

# 3. 在 knowledge/INDEX.md 清单中添加一行
# 4. 按模板填充 INDEX.md（含 L0 底线）、framework/、guidelines/、domain/

# 5. 如果是 Go 工程，可直接复用 skills/go/
# 6. 为该工程在 agents/code-review/ 下创建子目录：
mkdir -p "$AI_WORKFLOWS_DIR/agents/code-review/lessons/$NEW"
mkdir -p "$AI_WORKFLOWS_DIR/agents/code-review/exemptions/$NEW"
# 复制 per-repo 配置模板：
cp "$AI_WORKFLOWS_DIR/agents/code-review/config/per-repo/_TEMPLATE.yaml" \
   "$AI_WORKFLOWS_DIR/agents/code-review/config/per-repo/$NEW.yaml"

# 7. 跑规模自检
bash "$AI_WORKFLOWS_DIR/script/check-scale.sh"
```

## 二、规模约束（新工程必须遵守）

| 约束项 | 上限 |
|--------|------|
| 工程 L0 条数（INDEX.md 顶部） | ≤ 20 条 |
| framework 文件数 | ≤ 5 个 |
| 单个 Knowledge 文件行数 | ≤ 500 行 |
| 初始 domain 文件数 | 建议 ≤ 3 个（按需增长） |

## 三、如果新工程是 C++ / Python / Rust 等

1. 语言通用的 Skill 放 `skills/common/`
2. 语言专属的 Skill 放 `skills/<lang>/`（如 `skills/cpp/code-review/`）
3. 在工程 INDEX.md 顶部声明语言：`language: cpp`，便于 Agent 加载对应 Skill 集

## 四、检查清单（PR 合入前自查）

- [ ] `knowledge/INDEX.md` 已添加工程行
- [ ] 新工程的 `INDEX.md` 已填好 L0/L1/L2 索引
- [ ] 相关 `framework/*.md` 文件已创建（至少 architecture.md + tech-stack.md）
- [ ] 至少 1 个 `guidelines/*.md` 已填（如 coding-style.md）
- [ ] `agents/code-review/lessons/<工程>/` 目录已建（可只放 .gitkeep）
- [ ] `agents/code-review/config/per-repo/<工程>.yaml` 已填
- [ ] `bash script/check-scale.sh` 全部通过
