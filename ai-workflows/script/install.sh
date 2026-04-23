#!/usr/bin/env bash
# ai-workflows/script/install.sh
#
# 把 base_rule.md 软链到各 IDE/平台的规则目录，更新一次，全平台同步生效。
# 自动检测：CodeBuddy / Claude Code / Cursor。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_WORKFLOWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_RULE="$AI_WORKFLOWS_DIR/base_rule.md"
AGENTS_MD="$AI_WORKFLOWS_DIR/AGENTS.md"

echo "════════════════════════════════════════════════════════════"
echo "  ai-workflows install"
echo "  AI_WORKFLOWS_DIR = $AI_WORKFLOWS_DIR"
echo "════════════════════════════════════════════════════════════"

if [[ ! -f "$BASE_RULE" ]]; then
    echo "❌ 未找到 base_rule.md: $BASE_RULE"
    exit 1
fi

# 通用软链函数：link_rule <target_dir> <target_filename>
link_rule() {
    local target_dir="$1"
    local target_name="$2"
    local target="$target_dir/$target_name"

    if [[ ! -d "$target_dir" ]]; then
        echo "  ⊘ 跳过（目录不存在）：$target_dir"
        return
    fi

    # 备份旧文件
    if [[ -e "$target" && ! -L "$target" ]]; then
        local backup="${target}.bak.$(date +%s)"
        mv "$target" "$backup"
        echo "  ⚠️  已备份原文件：$backup"
    fi

    ln -sfn "$BASE_RULE" "$target"
    echo "  ✓ 软链 → $target"
}

# 1) CodeBuddy
CODEBUDDY_DIR="$HOME/.codebuddy/rules"
mkdir -p "$CODEBUDDY_DIR"
echo "▸ CodeBuddy:"
link_rule "$CODEBUDDY_DIR" "base_rule.md"

# 2) Claude Code（user 级）
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"
echo "▸ Claude Code:"
# Claude Code 规则通常在 ~/.claude/CLAUDE.md 或 project 级 ./CLAUDE.md
link_rule "$CLAUDE_DIR" "CLAUDE.md"

# 3) Cursor（user 级全局规则）
CURSOR_DIR="$HOME/.cursor/rules"
mkdir -p "$CURSOR_DIR"
echo "▸ Cursor:"
link_rule "$CURSOR_DIR" "base_rule.mdc"

# 4) 设置环境变量提示
ENV_LINE="export AI_WORKFLOWS_DIR=\"$AI_WORKFLOWS_DIR\""
echo ""
echo "▸ 环境变量"
echo "  请把下面这行追加到 ~/.zshrc 或 ~/.bashrc："
echo ""
echo "      $ENV_LINE"
echo ""

# 5) 可选：写入 智能体平台 平台配置提示
echo "▸ 智能体平台 智能体平台（手动配置）"
echo "  System Prompt: 强制读取 $AGENTS_MD"
echo "  Rule:          $BASE_RULE"
echo ""

echo "════════════════════════════════════════════════════════════"
echo "✅ 安装完成"
echo ""
echo "下一步："
echo "  1. 执行：source ~/.zshrc   （或 ~/.bashrc）"
echo "  2. 执行：bash $SCRIPT_DIR/doctor.sh   进行环境自检"
echo "  3. 在 IDE 中打开 backend-service，让 AI 读取 AGENTS.md"
echo "════════════════════════════════════════════════════════════"
