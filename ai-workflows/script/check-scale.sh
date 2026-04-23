#!/usr/bin/env bash
# ai-workflows/script/check-scale.sh
#
# 上下文规模体检报告：输出每个工程/Skill/Agent 的规模，并检查是否超过约束上限，
# 便于长期监控是否因"随便往文件里塞东西"而腐化。
#
# 用法：
#   bash script/check-scale.sh            # 普通输出
#   bash script/check-scale.sh --strict   # 超限时以非 0 退出码退出（用于 CI / git hook）

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_WORKFLOWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

STRICT=0
[[ "${1:-}" == "--strict" ]] && STRICT=1

# ── 约束上限（与 AGENTS.md §7 保持一致） ─────────────────────────
LIMIT_GLOBAL_L0=10          # AGENTS.md §1.1 的 L0 条数
LIMIT_PROJECT_L0=20         # 单工程 L0 条数（工程 INDEX.md 顶部）
LIMIT_SKILL_LINES=300       # 单个 SKILL.md 行数
LIMIT_KNOWLEDGE_LINES=500   # 单个 knowledge/*.md 行数
LIMIT_AGENTS_MD_LINES=200   # AGENTS.md 行数

# ── 颜色 ─────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED=$'\033[31m'; YELLOW=$'\033[33m'; GREEN=$'\033[32m'; BOLD=$'\033[1m'; RESET=$'\033[0m'
else
    RED=''; YELLOW=''; GREEN=''; BOLD=''; RESET=''
fi

TOTAL_WARN=0
TOTAL_FAIL=0

ok()   { echo "  ${GREEN}✅${RESET} $1"; }
warn() { echo "  ${YELLOW}⚠️  $1${RESET}"; TOTAL_WARN=$((TOTAL_WARN+1)); }
fail() { echo "  ${RED}❌ $1${RESET}";   TOTAL_FAIL=$((TOTAL_FAIL+1)); }

# 计算一个 md 的行数（排除空行）
count_md_lines() {
    [[ -f "$1" ]] && grep -c -v '^[[:space:]]*$' "$1" || echo 0
}

# 计算 AGENTS.md §1.1 全局 L0 的条数（顶层有序列表项数）
count_global_l0() {
    local f="$AI_WORKFLOWS_DIR/AGENTS.md"
    [[ -f "$f" ]] || { echo 0; return; }
    # 提取 "### 1.1 全局 L0" 到下一个 "### " 之间的顶层有序列表项
    awk '
        /^### 1\.1/ {grab=1; next}
        /^### / {grab=0}
        grab && /^[0-9]+\. / {count++}
        END {print count+0}
    ' "$f"
}

# 计算工程 INDEX.md 的 L0 条数（顶部的 "## L0 底线规则" 段）
count_project_l0() {
    local f="$1"
    [[ -f "$f" ]] || { echo 0; return; }
    awk '
        /^## L0/ {grab=1; next}
        grab && /^## / {grab=0}
        grab && /^[0-9]+\. / {count++}
        END {print count+0}
    ' "$f"
}

# ── Header ───────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════════"
echo "${BOLD}  ai-workflows · 上下文规模体检报告${RESET}"
echo "  AI_WORKFLOWS_DIR = $AI_WORKFLOWS_DIR"
echo "  strict mode = $STRICT"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── 1. 全局入口规模 ─────────────────────────────────────────────
echo "${BOLD}▸ 全局入口${RESET}"

agents_md_lines=$(count_md_lines "$AI_WORKFLOWS_DIR/AGENTS.md")
if [[ $agents_md_lines -le $LIMIT_AGENTS_MD_LINES ]]; then
    ok "AGENTS.md 行数：$agents_md_lines / $LIMIT_AGENTS_MD_LINES"
else
    fail "AGENTS.md 行数超标：$agents_md_lines / $LIMIT_AGENTS_MD_LINES （建议拆分到 knowledge/）"
fi

global_l0=$(count_global_l0)
if [[ $global_l0 -le $LIMIT_GLOBAL_L0 ]]; then
    ok "全局 L0 条数：$global_l0 / $LIMIT_GLOBAL_L0"
else
    fail "全局 L0 超标：$global_l0 / $LIMIT_GLOBAL_L0 （AGENTS.md §1.1 太长，拆到工程 L0 或 guidelines/）"
fi

base_rule_lines=$(count_md_lines "$AI_WORKFLOWS_DIR/base_rule.md")
ok "base_rule.md 行数：$base_rule_lines"

echo ""

# ── 2. 工程清单 ─────────────────────────────────────────────────
echo "${BOLD}▸ 工程清单${RESET}"

PROJECTS=()
for d in "$AI_WORKFLOWS_DIR"/knowledge/*/; do
    name="$(basename "$d")"
    # 跳过模板目录
    [[ "$name" == _* ]] && continue
    PROJECTS+=("$name")
done

if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    warn "knowledge/ 下没有任何工程"
else
    ok "已接入工程数：${#PROJECTS[@]}（${PROJECTS[*]}）"
fi

echo ""

# ── 3. 每工程规模 ───────────────────────────────────────────────
for proj in "${PROJECTS[@]}"; do
    echo "${BOLD}▸ 工程：$proj${RESET}"
    proj_dir="$AI_WORKFLOWS_DIR/knowledge/$proj"
    index="$proj_dir/INDEX.md"

    # 3.1 INDEX.md 存在性
    if [[ ! -f "$index" ]]; then
        fail "缺少 $proj/INDEX.md"
        echo ""
        continue
    fi

    # 3.2 工程 L0 条数
    proj_l0=$(count_project_l0 "$index")
    if [[ $proj_l0 -eq 0 ]]; then
        warn "工程 L0 条数为 0（建议至少 1 条核心规则）"
    elif [[ $proj_l0 -le $LIMIT_PROJECT_L0 ]]; then
        ok "工程 L0 条数：$proj_l0 / $LIMIT_PROJECT_L0"
    else
        fail "工程 L0 超标：$proj_l0 / $LIMIT_PROJECT_L0 （只保留 Blocker 级，细节下放 guidelines/）"
    fi

    # 3.3 framework / guidelines / domain 文件数 & 单文件行数
    for sub in framework guidelines domain; do
        sub_dir="$proj_dir/$sub"
        [[ -d "$sub_dir" ]] || continue
        file_count=$(find "$sub_dir" -type f -name '*.md' | wc -l | tr -d ' ')
        max_lines=0
        max_file=""
        while IFS= read -r f; do
            l=$(count_md_lines "$f")
            if [[ $l -gt $max_lines ]]; then
                max_lines=$l
                max_file="$(basename "$f")"
            fi
        done < <(find "$sub_dir" -type f -name '*.md')

        if [[ $max_lines -gt $LIMIT_KNOWLEDGE_LINES ]]; then
            fail "$sub/: $file_count 个文件，最大 $max_file 有 $max_lines 行（超标，建议拆分）"
        else
            ok "$sub/: $file_count 个文件，最大 $max_file $max_lines 行"
        fi
    done

    # 3.4 估算典型任务加载量（示例：Go 代码 Review）
    review_file="$proj_dir/guidelines/review-rules.md"
    if [[ -f "$review_file" ]]; then
        review_lines=$(count_md_lines "$review_file")
        arch_lines=$(count_md_lines "$proj_dir/framework/architecture.md")
        index_lines=$(count_md_lines "$index")
        load=$((agents_md_lines + base_rule_lines + index_lines + review_lines + arch_lines))
        echo "  📊 典型 Review 任务加载估算：${load} 行（不含 diff 与 lessons）"
    fi

    echo ""
done

# ── 4. Skill 规模 ──────────────────────────────────────────────
echo "${BOLD}▸ Skills${RESET}"

SKILL_COUNT=0
for sk in $(find "$AI_WORKFLOWS_DIR/skills" -name 'SKILL.md' -type f 2>/dev/null | sort); do
    SKILL_COUNT=$((SKILL_COUNT+1))
    rel="${sk#$AI_WORKFLOWS_DIR/}"
    lines=$(count_md_lines "$sk")
    if [[ $lines -gt $LIMIT_SKILL_LINES ]]; then
        fail "$rel : $lines 行（超标 $LIMIT_SKILL_LINES，建议拆分）"
    else
        ok "$rel : $lines 行"
    fi
done
[[ $SKILL_COUNT -eq 0 ]] && warn "skills/ 下没有找到任何 SKILL.md"

echo ""

# ── 5. Agent 的 per-repo 配置完整性 ─────────────────────────────
echo "${BOLD}▸ Agent code-review per-repo 配置${RESET}"

PER_REPO_DIR="$AI_WORKFLOWS_DIR/agents/code-review/config/per-repo"
if [[ -d "$PER_REPO_DIR" ]]; then
    for proj in "${PROJECTS[@]}"; do
        cfg="$PER_REPO_DIR/$proj.yaml"
        lessons="$AI_WORKFLOWS_DIR/agents/code-review/lessons/$proj"
        if [[ -f "$cfg" ]]; then
            ok "$proj.yaml 存在"
        else
            warn "$proj.yaml 缺失（新工程未完成 Agent 接入）"
        fi
        if [[ -d "$lessons" ]]; then
            ok "lessons/$proj/ 目录存在"
        else
            warn "lessons/$proj/ 目录缺失"
        fi
    done
else
    fail "per-repo 目录不存在：$PER_REPO_DIR"
fi

echo ""

# ── 6. 长期趋势（lessons 与 exemptions 增长） ───────────────────
echo "${BOLD}▸ lessons / exemptions 累积${RESET}"
for proj in "${PROJECTS[@]}"; do
    ldir="$AI_WORKFLOWS_DIR/agents/code-review/lessons/$proj"
    edir="$AI_WORKFLOWS_DIR/agents/code-review/exemptions/$proj"
    lcount=0; ecount=0
    [[ -d "$ldir" ]] && lcount=$(find "$ldir" -maxdepth 1 -type f -name 'lesson-*.md' 2>/dev/null | wc -l | tr -d ' ')
    [[ -d "$edir" ]] && ecount=$(find "$edir" -maxdepth 1 -type f -name 'exemption-*.md' 2>/dev/null | wc -l | tr -d ' ')
    echo "  📁 $proj: lessons=$lcount, exemptions=$ecount"
done

echo ""

# ── 结语 ────────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════════"
if [[ $TOTAL_FAIL -eq 0 && $TOTAL_WARN -eq 0 ]]; then
    echo "${GREEN}  ✅ 体检全部通过${RESET}"
elif [[ $TOTAL_FAIL -eq 0 ]]; then
    echo "${YELLOW}  ⚠️  警告 $TOTAL_WARN 条，未发现超限${RESET}"
else
    echo "${RED}  ❌ 超限 $TOTAL_FAIL 条  ⚠️  警告 $TOTAL_WARN 条${RESET}"
fi
echo "════════════════════════════════════════════════════════════"

if [[ $STRICT -eq 1 && $TOTAL_FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
