#!/usr/bin/env bash
# ai-workflows/script/run-agent.sh
#
# 通用 Agent 启动器。由 crontab 或 webhook-server 调用。
#
# 用法：
#   run-agent.sh <agent_name> <action>
# 例：
#   run-agent.sh code-review archive
#   run-agent.sh test-env-inspector run

set -euo pipefail

AGENT="${1:-}"
ACTION="${2:-run}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AI_WORKFLOWS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [[ -z "$AGENT" ]]; then
    echo "Usage: run-agent.sh <agent_name> [action]"
    exit 1
fi

AGENT_DIR="$AI_WORKFLOWS_DIR/agents/$AGENT"
if [[ ! -d "$AGENT_DIR" ]]; then
    echo "❌ Agent not found: $AGENT_DIR"
    exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"
LOG="/tmp/ai-agent-$AGENT-$TS.log"

echo "[$(date)] run-agent.sh $AGENT $ACTION" >> "$LOG"
echo "  AGENT_DIR=$AGENT_DIR"                >> "$LOG"
echo "  AI_WORKFLOWS_DIR=$AI_WORKFLOWS_DIR"  >> "$LOG"

# 这里是**启动占位**：真实实现应该调用 webhook-server 内的 Python/Go 模块
# 或直接通过 AI CLI（claude / codebuddy-cli 等）把 AGENT.md + 上下文传入执行
#
# 示例（伪代码）：
#
#   claude --file "$AGENT_DIR/AGENT.md" \
#          --file "$AI_WORKFLOWS_DIR/AGENTS.md" \
#          --task "$ACTION" \
#          --workdir "$AI_WORKFLOWS_DIR" \
#     >> "$LOG" 2>&1
#
# 为避免误跑，当前只记录日志后退出。

echo "⚠️  run-agent.sh 是占位脚本，请实际接入 CLI 后启用。"
echo "⚠️  日志：$LOG"
