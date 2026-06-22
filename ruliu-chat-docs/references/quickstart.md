# 新电脑最短流程

目标：用户把这个 skill 文件夹复制到新电脑的 Codex skill 目录后，agent 能用最少命令读写 KU 文档和做内搜。

## 1. 放 skill

把整个 `ruliu-chat-docs` 文件夹放到：

```bash
$HOME/.codex/skills/ruliu-chat-docs
```

检查文件：

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/check-deps.sh"
```

## 2. 保存 UGate token

UGate token 是 KU 文档读取/编辑和企业内搜的个人身份凭据。`ku-darwin-arm64` 会读取：

```text
~/.config/uuap/.eac_ugate_token_<邮箱前缀>
```

最短命令：

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<你的邮箱前缀>"
```

脚本会打开 `https://uuap.baidu.com/agent/token`，用户在浏览器里复制 token，脚本自动写入缓存文件。

如果新电脑浏览器还没有通过百度网关/SSO，先在浏览器完成登录，刷新 `https://uuap.baidu.com/agent/token`，看到 `ugate token: ...` 后再复制。

如果 Codex CLI / Claude Code CLI 的沙箱不能打开浏览器或读取剪贴板，用纯终端模式：

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<你的邮箱前缀>" --stdin
```

然后把浏览器里复制到的整行 `ugate token: eyJ...` 粘贴到终端，按 `Ctrl-D`。

## 3. 读取 KU 文档

Markdown：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol markdown --show-doc-info'
```

编辑器 JSON：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol json --show-doc-info'
```

返回结构：

- `result.text`：`protocol=markdown/html/aihtml/mdhtml` 时优先取这里。
- `result.content`：`protocol=json` 时取这里，是编辑器 JSON。
- `result.docInfo`：标题、创建者、发布时间、知识库信息等元数据。

评论不在正文 JSON 里，评论要单独查：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" query-comments --doc-id "<docGuid>"'
```

## 4. 创建 KU 文档

创建到个人知识库：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; INFO="$("$KU" query-user-info --username "$SANDBOX_USERNAME")"; REPO_ID="$(printf "%s" "$INFO" | sed -n "s/.*\"repositoryGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; "$KU" create-doc --repo-id "$REPO_ID" --username "$SANDBOX_USERNAME" --title "新文档标题" --content "正文内容" --process-images=false'
```

不要省略 `--repo-id`。先用 `query-user-info` 取个人知识库的 `repositoryGuid`，再创建文档。

创建到某个目录下：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" create-doc --repo-id "<repositoryGuid>" --parent-doc-id "<parentDocGuid>" --username "$SANDBOX_USERNAME" --title "新文档标题" --content "正文内容"'
```

## 5. 追加内容

`edit-content` 只写草稿，必须再 `publish-doc`。

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"heading","level":2,"children":[{"text":"新增小节"}]},{"type":"paragraph","children":[{"text":"这里是新增内容。"}]}]}]'\''; "$KU" edit-content --doc-id "<docGuid>" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "<docGuid>" --protocol markdown --show-doc-info'
```

## 6. 修改已有内容

不要直接追加“修正说明”。正确流程：

1. `query-content --protocol json` 读回全文。
2. 本地保存备份。
3. 按文字锚点、表格行或 `blockId` 定位要改的节点。
4. 修改本地 JSON。
5. 用 `edit-content --editor-mode cover` 覆盖正文。
6. `publish-doc` 发布。
7. 再读回 markdown/json，确认旧内容消失，新内容在原位置。

注意：`query-content --protocol json` 读回的 `result.content[0]` 通常是标题节点。用 `cover` 写正文时，不要把标题节点重复写进正文。

## 7. 删除文档

删除不可恢复，agent 必须先让用户明确确认。

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" delete-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"'
```

## 8. 企业内搜

知识库语义搜索：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/ku_search.py --word "关键词" --page 1 --page-size 10'
```

普通内搜：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/neisou_search.py --word "关键词" --page 1 --page-size 10'
```

搜人：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/address_search.py --type corpuser --q "姓名或邮箱前缀"'
```

搜群：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/address_search.py --type group --q "群名或群号"'
```
