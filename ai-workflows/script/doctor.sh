#!/usr/bin/env bash
# ai-workflows/script/doctor.sh
#
# 环境自检：检查软链、环境变量、必备文件是否齐全

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_WORKFLOWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

PASS=0
WARN=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        echo "  ✅ $name"
        ((PASS++))
    else
        echo "  ❌ $name"
        ((FAIL++))
    fi
}

warn() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        echo "  ✅ $name"
        ((PASS++))
    else
        echo "  ⚠️  $name"
        ((WARN++))
    fi
}

echo "════════════════════════════════════════════════════════════"
echo "  ai-workflows 环境自检"
echo "  AI_WORKFLOWS_DIR = $AI_WORKFLOWS_DIR"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "▸ 核心文件"
check "AGENTS.md 存在"      "[[ -f '$AI_WORKFLOWS_DIR/AGENTS.md' ]]"
check "base_rule.md 存在"   "[[ -f '$AI_WORKFLOWS_DIR/base_rule.md' ]]"
check "knowledge/INDEX.md 存在"   "[[ -f '$AI_WORKFLOWS_DIR/knowledge/INDEX.md' ]]"
check "backend-service INDEX 存在" "[[ -f '$AI_WORKFLOWS_DIR/knowledge/backend-service/INDEX.md' ]]"

echo ""
echo "▸ Skills（按分类）"
for s in go/code-review go/coding go/create-module go/config common/design-doc common/mr common/test; do
    check "skills/$s/SKILL.md"  "[[ -f '$AI_WORKFLOWS_DIR/skills/$s/SKILL.md' ]]"
done

echo ""
echo "▸ Agents"
for a in code-review alert-analysis loop-frame; do
    check "agents/$a/AGENT.md" "[[ -f '$AI_WORKFLOWS_DIR/agents/$a/AGENT.md' ]]"
done

echo ""
echo "▸ 多工程就绪结构"
check "knowledge/_TEMPLATE/ 存在"             "[[ -d '$AI_WORKFLOWS_DIR/knowledge/_TEMPLATE' ]]"
check "agents/code-review/config/per-repo/"   "[[ -d '$AI_WORKFLOWS_DIR/agents/code-review/config/per-repo' ]]"
check "agents/code-review/lessons/ 分目录"    "[[ -d '$AI_WORKFLOWS_DIR/agents/code-review/lessons/backend-service' ]]"
check "script/check-scale.sh 存在"            "[[ -f '$AI_WORKFLOWS_DIR/script/check-scale.sh' ]]"

echo ""
echo "▸ 环境变量"
warn "AI_WORKFLOWS_DIR 已导出" "[[ -n \"\${AI_WORKFLOWS_DIR:-}\" ]]"

echo ""
echo "▸ 平台软链"
warn "CodeBuddy 软链"  "[[ -L \"\$HOME/.codebuddy/rules/base_rule.md\" ]]"
warn "Claude Code 软链" "[[ -L \"\$HOME/.claude/CLAUDE.md\" ]]"
warn "Cursor 软链"      "[[ -L \"\$HOME/.cursor/rules/base_rule.mdc\" ]]"

echo ""
echo "▸ backend-service 工程"
warn "~/projects/backend-service 存在" "[[ -d \"\$HOME/projects/backend-service\" ]]"

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  通过：$PASS   警告：$WARN   失败：$FAIL"
echo "════════════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
