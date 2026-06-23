---
name: ruliu-docs
description: 如流聊天和如流/KU 文档操作入口。Use when the user mentions 如流、RuLiu、Infoflow、ku.baidu-int.com、知识库、KU 文档、读取/创建/编辑/发布/删除/评论/权限/子文档/在线表格/数据表、企业内搜、知识库搜索、会议/周报/OKR/通讯录搜索，或需要把内容写成如流文档、表格、图片、附件、Mermaid/流程图。
---

# ruliu-docs

此 skill 面向 `ruliu-docs` 文件夹，提供如流/KU 文档读取、搜索、创建、编辑、发布、删除、子文档、表格、图片、附件和图示内容写入的操作经验。技能名和文件夹名固定为 `ruliu-docs`。

## 先读哪些文件

- 普通读、创建、追加、删除、搜索：直接按本文命令做。
- 需要查 KU CLI 完整命令、参数、响应字段、在线表格、数据表、权限、评论、附件、版本、复制、移动、删除：读 `deps/ku-doc-manage/references/API_INDEX.md`，再读对应子命令文档，例如 `query_content.md`、`create_doc.md`、`edit_content.md`。
- 使用 `edit-content --editor-mode mdsl` 做局部编辑前：读 `deps/ku-doc-manage/references/edit_content.md` 和 `deps/ku-doc-manage/references/mdsl_edit_agent.md`。
- 替换、删除中间内容、插入到指定标题下、改表格某一行：先读 `references/ku-doc-editing.md`。
- 写产品方案、PRD、决策文档、需求分析：先读 `references/ku-doc-writing/README.md`，必要时读其中 examples。
- 表格、图片、附件、HTML demo 截图、Mermaid/流程图：先读 `references/ruliu-writing-tips.md`，复杂节点再读 `references/ku-doc-editing.md`。

## 最小运行文件

- KU CLI：`deps/ku-doc-manage/bin/ku-darwin-arm64`
- KU 配置：`deps/ku-doc-manage/bin/config.yaml`
- 企业内搜：`deps/enterprise-search/scripts/`
- UGate 缓存脚本：`scripts/cache-ugate-token.sh`
- 依赖检查：`scripts/check-deps.sh`

永远优先直接调用 `ku-darwin-arm64`，不要依赖 `bin/ku` 包装器下载路径。每条 KU/内搜命令都设置 `SANDBOX_USERNAME=<uuap>`。

## 认证

KU 和内搜依赖本机 UGate 缓存：

```text
~/.config/uuap/.eac_ugate_token_<uuap>
```

先用大白话引导用户在本机普通浏览器打开：

```text
https://uuap.baidu.com/agent/token
```

如果页面没有显示 `ugate token: ...`，先让用户过百度网关/SSO，再刷新。让用户复制页面里的 token 内容，然后停止操作，等待用户明确回复“已复制”或直接提供 token 后，再运行本地脚本缓存。不要先启动脚本让它长时间等待剪贴板。

用户只复制到剪贴板时：

```bash
bash "$HOME/.codex/skills/ruliu-docs/scripts/cache-ugate-token.sh" "<uuap>"
```

纯终端、沙箱不能读剪贴板，或用户已经在聊天里提供 token 时，用 stdin 模式把 token 传给脚本。可以处理用户发来的 token，但不要在回复、日志、文档或仓库里复述完整 token：

```bash
bash "$HOME/.codex/skills/ruliu-docs/scripts/cache-ugate-token.sh" "<uuap>" --stdin
```

## 运行前检查

确认工具文件：

```bash
bash "$HOME/.codex/skills/ruliu-docs/scripts/check-deps.sh"
```

确认身份，并从返回里拿个人知识库 `userPersonalRepo.repositoryGuid`：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; "$KU" query-user-info --username "$SANDBOX_USERNAME"'
```

## 读取文档

普通 KU URL 形态：

```text
https://ku.baidu-int.com/knowledge/<spaceGuid>/<groupGuid>/<repositoryGuid>/<docGuid>
```

最后一段是 `docGuid`，倒数第二段是 `repositoryGuid`。

读 Markdown 文本：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; "$KU" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol markdown --show-doc-info'
```

读编辑器 JSON：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; "$KU" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol json --show-doc-info'
```

要理解结构：`protocol=markdown` 的正文在 `result.text`；`protocol=json` 的正文在 `result.content`；评论不在正文 JSON 中，用 `query-comments` 单独读。

## 创建文档和子文档

在用户个人知识库创建文档时，不要省略 `--repo-id`。先 `query-user-info`，解析 `userPersonalRepo.repositoryGuid`。

不要只依赖 `create-doc --content` 来写正文。实测中 `create-doc` 能创建标题和返回 `docGuid`，但正文可能落在 title 节点的 `markdown.content` 元数据里，而不是可见正文区。稳定流程是：

1. `create-doc --create-mode empty` 创建文档并拿 `docGuid`。
2. `edit-content --editor-mode append` 写入正文 card。
3. `publish-doc` 发布。
4. `query-content --protocol markdown` 读回确认标题、正文和链接。

创建个人知识库文档并写入正文：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; INFO="$("$KU" query-user-info --username "$SANDBOX_USERNAME")"; REPO_ID="$(printf "%s" "$INFO" | sed -n "s/.*\"repositoryGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; if [ -z "$REPO_ID" ]; then echo "ERROR: repositoryGuid not found" >&2; exit 1; fi; CREATE="$("$KU" create-doc --repo-id "$REPO_ID" --username "$SANDBOX_USERNAME" --title "文档标题" --create-mode empty --process-images=false)"; DOC_ID="$(printf "%s" "$CREATE" | sed -n "s/.*\"docGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; if [ -z "$DOC_ID" ]; then echo "ERROR: docGuid not found" >&2; printf "%s\n" "$CREATE"; exit 1; fi; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"正文内容"}]}]}]'\''; "$KU" edit-content --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "$DOC_ID" --protocol markdown --show-doc-info'
```

创建子文档：KU 文档可当目录用。传父文档 ID：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; CREATE="$("$KU" create-doc --repo-id "<repositoryGuid>" --parent-doc-id "<parentDocGuid>" --username "$SANDBOX_USERNAME" --title "子文档标题" --create-mode empty --process-images=false)"; DOC_ID="$(printf "%s" "$CREATE" | sed -n "s/.*\"docGuid\": *\"\([^\"]*\)\".*/\1/p" | head -1)"; if [ -z "$DOC_ID" ]; then echo "ERROR: docGuid not found" >&2; printf "%s\n" "$CREATE"; exit 1; fi; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"正文内容"}]}]}]'\''; "$KU" edit-content --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "$DOC_ID" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "$DOC_ID" --protocol markdown --show-doc-info'
```

创建完必须读回，确认标题、URL、层级和正文可见。

## 编辑文档

`edit-content` 只保存草稿，必须再运行 `publish-doc`。

默认用 `append`，适合新增小节、追加表格、追加图片、追加总结：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; KU="$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64"; OPS='\''[{"mode":"append","withNewCard":true,"json":[{"type":"heading","level":2,"children":[{"text":"新增小节"}]},{"type":"paragraph","children":[{"text":"新增正文。"}]}]}]'\''; "$KU" edit-content --doc-id "<docGuid>" --username "$SANDBOX_USERNAME" --editor-mode append --operations "$OPS"; "$KU" publish-doc --doc-id "<docGuid>" --username "$SANDBOX_USERNAME"; "$KU" query-content --doc-id "<docGuid>" --protocol markdown --show-doc-info'
```

以下情况不要追加“修正说明”，必须 JSON 定位后 `cover` 写回：替换原文、删除原文、插入到指定标题下、修改表格行/单元格。流程：

1. `query-content --protocol json` 读取并保存本地备份。
2. 用文字锚点、标题、表格行文本或 `blockId` 定位目标节点。
3. 只修改相关节点，保留无关节点。
4. `edit-content --editor-mode cover` 写回。
5. `publish-doc`。
6. 用 markdown/json 双读回验证旧内容消失、新内容在原位置。

覆盖时不要把返回的标题节点 `result.content[0]` 写进正文 payload，否则标题可能重复出现在正文。

## 搜索

知识库搜索：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 ku_search.py --word "关键词" --page 1 --page-size 10'
```

企业内搜：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 neisou_search.py --word "关键词" --page 1'
```

会议、周报、OKR、通讯录也在 `deps/enterprise-search/scripts/`，按脚本名选择。通讯录：

```bash
bash -lc 'export SANDBOX_USERNAME="<uuap>"; SKILL="$HOME/.codex/skills/ruliu-docs"; cd "$SKILL/deps/enterprise-search/scripts"; python3 address_search.py --type corpuser --q "姓名或邮箱前缀"'
```

## 表格、图片和图

- 表格要写成 KU `table` 节点，不要退化成代码块；列宽在 `table.data.width`。
- 总宽建议约 `1260`；序号列 `60-90`；普通文本列 `180-320`；图片列 `520-820`。
- 表头灰底不是全局表格字段，要给首行每个 `table-cell.data.backgroundColor` 写 `rgb(231, 230, 230)`。
- 图片先 `upload-attachment`，再用目标文档自己的 `attachId` 生成 `imageDownloadAddress`，不要直接复用别的文档图片 URL。
- HTML demo 先截图成 PNG，再上传并作为 `image` 节点插入；HTML 原文件可另用附件卡片保存。
- Mermaid 在已有文档中表现为 `block-code` + `language:"mermaid"`，不保证直接渲染成图。用户要可视化图时，优先生成图片后作为 image 插入。
- 复杂表格、图片、附件、流程图节点模板见 `references/ku-doc-editing.md`。

## 写作要求

写 KU 产品/需求/方案文档时：

- 只写能帮助决策的信息，不为了像 PRD 而堆章节。
- 分清“已确定”和“待讨论”。
- 结论先行，但结论要是可判断的句子。
- 表格列数服务决策问题，能三列讲清楚就不要扩成六列。
- 先定义口径，再放推算。
- 写完读回检查；如果用户纠正了结构、表格、语气或范围，把可复用经验更新到 `references/ku-doc-writing/README.md` 或 examples。

## 安全边界

- 可以处理用户提供的 UGate token、Bearer token、AK/SK，但不打印、不复述、不写入文档或仓库。
- 不把 `private/`、本地 token 缓存、个人密钥打包进仓库。
- 删除文档前二次确认。
- 对替换类任务不要用 append 糊过去；必须改真实位置并读回验证。
