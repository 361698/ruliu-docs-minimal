---
name: ruliu-chat-docs
description: Minimal Baidu KU/RuLiu document and enterprise-search runtime. Use for ku.baidu-int.com document read/create/edit/delete tasks and Baidu internal search when this skill is installed.
---

# ruliu-chat-docs

This repository is intentionally minimal. It only carries the runnable local
tools needed by an agent; onboarding prompts and task-specific instructions
should be provided outside the repository.

## Runtime Files

- KU CLI: `deps/ku-doc-manage/bin/ku-darwin-arm64`
- KU CLI config: `deps/ku-doc-manage/bin/config.yaml`
- Enterprise search scripts: `deps/enterprise-search/scripts/`
- UGate cache helper: `scripts/cache-ugate-token.sh`
- Dependency check: `scripts/check-deps.sh`

## Credential Model

KU and enterprise-search use the local UGate cache:

```text
~/.config/uuap/.eac_ugate_token_<uuap>
```

Do not ask users to paste UGate tokens into chat. The user should obtain the
token in their own browser from:

```text
https://uuap.baidu.com/agent/token
```

Then cache it locally with:

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<uuap>"
```

For terminal-only or sandboxed environments:

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

Always set `SANDBOX_USERNAME=<uuap>` when running KU or search commands.
