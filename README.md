# ruliu-chat-docs 最小可运行包

这个目录是从现有几个如流/KU skill 中挑出来的最小版本，目标是让一台新 Mac 上的 Codex 能最快读写如流知识库文档，并能做企业内搜。

## 已挑出的内容

- `ruliu-chat-docs/`：可直接复制到 `~/.codex/skills/ruliu-chat-docs` 的 skill 文件夹。
- `ruliu-chat-docs/deps/ku-doc-manage/`：KU 文档读取、创建、编辑、发布、删除、评论、权限等命令，包含已下载好的 `ku-darwin-arm64`。
- `ruliu-chat-docs/deps/enterprise-search/`：内搜、知识库搜索、会议、周报、OKR、通讯录搜索脚本。
- `ruliu-chat-docs/deps/get-ugate-token/`：官方 UGate 缓存脚本，作为兜底参考。
- `ruliu-chat-docs/scripts/cache-ugate-token.sh`：新写的一键脚本，打开 UGate token 页面，等待用户复制 token，并保存到 `ku-darwin-arm64` 会读取的位置。
- `ruliu-chat-docs/references/quickstart.md`：新电脑最短流程和常用一行命令。
- `ruliu-chat-docs/references/ruliu-writing-tips.md`：从本地记忆、当前 Codex skill、几个桌面版本和同步项目里汇总的 KU 写入技巧。
- `ruliu-chat-docs/references/ku-doc-editing.md`：原有实测长手册，保留完整细节。
- `ruliu-chat-docs/references/ku-doc-writing/`：产品/需求类 KU 文档写作风格经验。

## 已剔除的内容

- `private/`：个人 token、AK/SK 一律不放入最小包。
- `infoflow-message-group/`：如流群机器人收发消息，本轮不需要。
- `knowledge-fetch/`：knowbase 拉取知识源，本轮先不用。
- `dumate-ent-info-sync/`：项目专项同步器，本轮只抽取其中可复用的 KU 写入经验。

## 新电脑最短使用

```bash
cp -R "/path/to/ruliu-chat-docs" "$HOME/.codex/skills/ruliu-chat-docs"
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "<你的邮箱前缀>"
```

读一个 KU 文档：

```bash
bash -lc 'export SANDBOX_USERNAME="<你的邮箱前缀>"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol markdown --show-doc-info'
```

更多命令见 `ruliu-chat-docs/references/quickstart.md`。
