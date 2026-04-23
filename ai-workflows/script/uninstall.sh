#!/usr/bin/env bash
# ai-workflows/script/uninstall.sh
#
# 移除 install.sh 创建的软链（不动业务数据）。

set -euo pipefail

echo "════════════════════════════════════════════════════════════"
echo "  ai-workflows uninstall"
echo "════════════════════════════════════════════════════════════"

remove_link() {
    local target="$1"
    if [[ -L "$target" ]]; then
        rm "$target"
        echo "  ✓ 已删除软链：$target"
    elif [[ -e "$target" ]]; then
        echo "  ⚠️  已跳过（非软链，可能是你本地的文件）：$target"
    else
        echo "  ⊘ 不存在：$target"
    fi
}

remove_link "$HOME/.codebuddy/rules/base_rule.md"
remove_link "$HOME/.claude/CLAUDE.md"
remove_link "$HOME/.cursor/rules/base_rule.mdc"

echo ""
echo "✅ 卸载完成"
echo ""
echo "注意：lessons/ exemptions/ feedback/ 等业务数据未被删除。"
