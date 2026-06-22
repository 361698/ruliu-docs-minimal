#!/usr/bin/env bash
# Source before manual commands if you want a stable skill path:
#   source ~/.codex/skills/ruliu-chat-docs/scripts/env.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

export RULIU_SKILL_DIR="${SKILL_DIR}"

if [ -n "${SANDBOX_USERNAME:-}" ]; then
  export BAIDU_CC_USERNAME="${BAIDU_CC_USERNAME:-$SANDBOX_USERNAME}"
elif [ -n "${BAIDU_CC_USERNAME:-}" ]; then
  export SANDBOX_USERNAME="$BAIDU_CC_USERNAME"
fi

true
