---
name: ruliu-chat-docs
description: Read, create, edit, publish, delete, and search Baidu internal KU/RuLiu documents. Use for ku.baidu-int.com document work and Baidu enterprise internal search. Minimal package: KU binary/config, enterprise-search Python scripts, UGate cache script, and writing guides.
---

# RuLiu Chat Docs Minimal

Use this skill whenever the user asks to read, create, edit, publish, delete, inspect, or search `ku.baidu-int.com` documents, or asks for Baidu enterprise internal search.

## First Rule

Do not browse or curl the UGate page yourself. A new user's browser may not have passed Baidu gateway/SSO yet. When UGate is missing, tell the user to open this URL in their normal browser:

```text
https://uuap.baidu.com/agent/token
```

If the page does not show `ugate token: ...`, the user must finish Baidu gateway/SSO login first, then refresh that URL and copy the token text.

## Minimal Runtime Dependencies

| Capability | Required files | Runtime credential |
|---|---|---|
| KU document read/write | `deps/ku-doc-manage/bin/ku-darwin-arm64` and `deps/ku-doc-manage/bin/config.yaml` | `~/.config/uuap/.eac_ugate_token_<uuap>` |
| Enterprise search / inner search | `deps/enterprise-search/scripts/*.py` | same UGate cache |
| UGate install | `scripts/cache-ugate-token.sh` | token copied by the user from browser |

`ku-darwin-arm64` alone is not enough. It needs the adjacent `config.yaml`.

## Setup Flow For New Codex CLI / Claude Code CLI

1. Ask for the user's UUAP. UUAP is the Baidu email prefix, for example `zhangsan` for `zhangsan@baidu.com`.
2. Set `SANDBOX_USERNAME=<uuap>` in every KU/search command.
3. Ensure UGate cache exists. If it does not, use one of the two flows below.

GUI Mac / clipboard flow:

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<uuap>"
```

Pure terminal / sandbox flow:

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

For the pure terminal flow, tell the user to:

1. Open `https://uuap.baidu.com/agent/token` in their normal browser.
2. Complete Baidu gateway/SSO if needed.
3. Copy the whole `ugate token: eyJ...` line or the raw JWT.
4. Paste it into the terminal running `--stdin`.
5. Press `Ctrl-D`.

Never ask the user to paste the token into chat.

## Stable KU Commands

Always use this shape. It avoids hidden `source` dependencies and avoids the wrapper download path.

Read Markdown:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; "$KU" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol markdown --show-doc-info'
```

Read editor JSON:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; "$KU" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol json --show-doc-info'
```

Create a document in the user's personal KU:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; INFO="$("$KU" query-user-info --username "$SANDBOX_USERNAME")"; REPO_ID="$(printf "%s" "$INFO" | sed -n "s/.*\"repositoryGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; "$KU" create-doc --repo-id "$REPO_ID" --username "$SANDBOX_USERNAME" --title "标题" --content "正文" --process-images=false'
```

Do not omit `--repo-id` for personal KU creation. Query `userPersonalRepo.repositoryGuid` first as shown above.

Append content, publish, then verify:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"heading","level":2,"children":[{"text":"新增小节"}]},{"type":"paragraph","children":[{"text":"新增正文。"}]}]}]'\''; "$KU" edit-content --doc-id "<docGuid>" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "<docGuid>" --protocol markdown --show-doc-info'
```

For replace/delete/insert-in-middle, do not append a correction note. First read `--protocol json`, save a local backup, modify the relevant editor JSON nodes, use `edit-content --editor-mode cover`, run `publish-doc`, then read back Markdown and JSON.

## Stable Enterprise Search Commands

KU document search:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 ku_search.py --word "关键词" --page 1 --page-size 10'
```

Inner search:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 neisou_search.py --word "关键词" --page 1'
```

Search people:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 address_search.py --type corpuser --q "姓名或邮箱前缀"'
```

Search groups:

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 address_search.py --type group --q "群名或群号"'
```

The bundled enterprise-search folder includes a local `requests.py` shim, so a fresh macOS Python does not need `pip install requests` for these scripts.

## Required Reading Before Risky Writes

- Existing content replacement/deletion/middle insertion: read `references/ku-doc-editing.md`.
- Product/requirement/decision document drafting: read `references/ku-doc-writing/README.md`.
- Condensed writing/editing checklist: read `references/ruliu-writing-tips.md`.

## Data Model Notes

- KU URL shape: `https://ku.baidu-int.com/knowledge/<space>/<group>/<repo>/<doc>`.
- Last URL segment is `docGuid`; previous segment is `repositoryGuid`.
- `protocol=markdown` returns text in `result.text`.
- `protocol=json` returns editor JSON in `result.content`.
- Comments are not in body JSON; use `query-comments`.
- `edit-content` writes a draft. Always run `publish-doc` for visible changes.
- Do not print or expose tokens from browser pages, `~/.config/uuap`, command output, or config files.
