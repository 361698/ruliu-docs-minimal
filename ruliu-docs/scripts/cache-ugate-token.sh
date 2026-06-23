#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  ./scripts/cache-ugate-token.sh <uuap>
  ./scripts/cache-ugate-token.sh <uuap> --test-url "https://ku.baidu-int.com/knowledge/..."
  ./scripts/cache-ugate-token.sh <uuap> --stdin

What it does:
  1. Reads the current clipboard, or reads token text from stdin with --stdin.
  2. Extracts a UGate JWT token from the copied page text or raw JWT token.
  3. Saves it to ~/.config/uuap/.eac_ugate_token_<uuap>, which ku-darwin-arm64 reads.

Run this after the user has copied the token page content. The script reads once; it does not wait for clipboard changes.
EOF
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ] || [ -z "${1:-}" ]; then
  usage
  exit 0
fi

UUAP="$1"
shift || true
TEST_URL=""
READ_STDIN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --test-url)
      TEST_URL="${2:-}"
      shift 2
      ;;
    --stdin)
      READ_STDIN=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TOKEN_URL="https://uuap.baidu.com/agent/token"
CACHE_DIR="$HOME/.config/uuap"
CACHE_FILE="$CACHE_DIR/.eac_ugate_token_${UUAP}"

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required" >&2
  exit 1
fi

if [ "$READ_STDIN" -eq 0 ] && ! command -v pbpaste >/dev/null 2>&1; then
  echo "pbpaste is required on macOS unless --stdin is used" >&2
  exit 1
fi

if [ "$READ_STDIN" -eq 1 ]; then
  cat <<EOF
请确认用户已经在浏览器访问：
  $TOKEN_URL

如果浏览器没有通过百度网关，请先让用户完成网关/SSO 登录，刷新后看到 token 页面。
然后把整行 "ugate token: eyJ..." 或纯 JWT 通过 stdin 传入，最后按 Ctrl-D。
EOF
else
  cat <<EOF
请先让用户在浏览器访问：
  $TOKEN_URL

如果浏览器没有通过百度网关，请先完成网关/SSO 登录，刷新后看到 token 页面。
确认用户已经复制 token 页面内容后，再运行本脚本。
本脚本只读取当前剪贴板一次；不会等待剪贴板变化，也不会把 token 打印出来。
EOF
fi

extract_token() {
  python3 -c '
import re
import sys

text = sys.stdin.read().strip()
if not text:
    sys.exit(1)

patterns = [
    r"ugate\s+token\s*[:：]\s*(eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)",
    r"\b(eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+)\b",
]

for pattern in patterns:
    match = re.search(pattern, text, flags=re.IGNORECASE | re.DOTALL)
    if match:
        print(match.group(1).strip())
        sys.exit(0)

sys.exit(1)
'
}

TOKEN=""
if [ "$READ_STDIN" -eq 1 ]; then
  TOKEN="$(cat | extract_token 2>/dev/null || true)"
else
  CLIP="$(pbpaste 2>/dev/null || true)"
  TOKEN="$(printf "%s" "$CLIP" | extract_token 2>/dev/null || true)"
fi

if [ -z "$TOKEN" ]; then
  echo "没有识别到 UGate JWT token。请确认用户已经复制页面里的 eyJ... token，然后再运行脚本。" >&2
  exit 1
fi

mkdir -p "$CACHE_DIR"
chmod 700 "$CACHE_DIR" 2>/dev/null || true
python3 - "$TOKEN" "$CACHE_FILE" <<'PY'
import json
import sys
from pathlib import Path

token = sys.argv[1].strip()
path = Path(sys.argv[2])
path.write_text(json.dumps({"token": token, "permanent": True}, ensure_ascii=False), encoding="utf-8")
path.chmod(0o600)
PY

echo "OK 已保存 UGate token 缓存：$CACHE_FILE"

if [ -n "$TEST_URL" ]; then
  export SANDBOX_USERNAME="$UUAP"
  "$SKILL_DIR/deps/ku-doc-manage/bin/ku-darwin-arm64" query-content --url "$TEST_URL" --protocol markdown --show-doc-info >/tmp/ruliu-docs-ku-test.json
  echo "OK KU 读取测试通过，结果已保存：/tmp/ruliu-docs-ku-test.json"
fi
