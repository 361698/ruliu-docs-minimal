#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
missing=0

check_path() {
  local path="$1"
  if [ -e "$path" ]; then
    echo "OK $path"
  else
    echo "MISSING $path"
    missing=1
  fi
}

check_exec() {
  local path="$1"
  if [ -x "$path" ]; then
    echo "OK executable $path"
  else
    echo "MISSING_OR_NOT_EXECUTABLE $path"
    missing=1
  fi
}

check_path "$SKILL_DIR/SKILL.md"
check_exec "$SKILL_DIR/deps/ku-doc-manage/bin/ku"
check_exec "$SKILL_DIR/deps/ku-doc-manage/bin/ku-darwin-arm64"
check_path "$SKILL_DIR/deps/enterprise-search/scripts/ku_search.py"
check_path "$SKILL_DIR/deps/get-ugate-token/getUgateToken.py"

uuap="${SANDBOX_USERNAME:-${BAIDU_CC_USERNAME:-}}"
if [ -n "$uuap" ] && [ -f "$HOME/.config/uuap/.eac_ugate_token_${uuap}" ]; then
  echo "OK UGate cache for $uuap"
elif [ -n "$uuap" ]; then
  echo "WARN UGate cache missing for $uuap"
else
  echo "WARN set SANDBOX_USERNAME=<uuap> before auth-sensitive commands"
fi

exit "$missing"
