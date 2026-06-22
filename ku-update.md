# 如流文档最小 Skill 包与写入技巧整理

更新时间：2026-06-22

## 这次产出

本次从当前 Codex skill、桌面多个 `ruliu-chat-docs` 版本、官方 zip、已有项目经验里，挑出了一个最小可运行的 `ruliu-chat-docs` skill 包。

目标是让新电脑上的 Codex 能最快完成两件事：

1. 读取、创建、编辑、发布、删除 KU / 如流知识库文档。
2. 使用企业内搜、知识库搜索、通讯录搜索等内部搜索能力。

## 验证状态

| 验证项 | 结果 |
|---|---|
| UGate 脚本语法检查 | 已通过 |
| UGate 脚本模拟剪贴板测试 | 已通过，可从 `ugate token: eyJ...` 中提取 JWT 并写入缓存 |
| UGate 脚本纯终端 `--stdin` 测试 | 已通过，适合 Codex CLI / Claude Code CLI 沙箱无法读剪贴板的情况 |
| UGate 缓存文件格式 | 已验证为 `{"token":"...","permanent":true}` |
| UGate 缓存文件权限 | 已验证为 `0600` |
| UGate 脚本真实 KU 读取闭环 | 已通过，能读取黑客松文档 `Agent Map 产品` |
| 临时 HOME 新电脑模拟 | 已通过，从空 HOME 写入 UGate 后可读取 KU |
| KU 创建、追加、发布、读回、删除闭环 | 已通过，创建时必须先 `query-user-info` 获取个人 `repositoryGuid` |
| 企业内搜脚本闭环 | 已通过，临时 HOME 下可跑 `ku_search.py`，且加载本地 `requests.py` 兼容层 |
| 最小包敏感文件检查 | 已通过，zip 中不包含 `private/`、UGate token、Comate token、infoflow 配置 |

## 最小包包含什么

| 模块 | 路径 | 作用 |
|---|---|---|
| Skill 入口 | `ruliu-chat-docs/SKILL.md` | 告诉 agent 何时使用本 skill，以及核心命令 |
| KU 文档命令 | `deps/ku-doc-manage/` | 读、建、改、删、移动、复制、权限、评论、附件、表格等 |
| Darwin 二进制 | `deps/ku-doc-manage/bin/ku-darwin-arm64` | 真正执行 KU API 调用的程序，新包已内置，不依赖首次下载 |
| 企业内搜 | `deps/enterprise-search/` | 内搜、KU 搜索、搜人、搜群、会议、周报、OKR |
| UGate 缓存参考 | `deps/get-ugate-token/` | 官方缓存脚本，作为兜底参考 |
| 一键 UGate 脚本 | `scripts/cache-ugate-token.sh` | 打开 token 页面、等待复制、写入 KU 程序会读取的缓存位置 |
| 新手教程 | `references/quickstart.md` | 新电脑最短流程和常用一行命令 |
| 写入技巧 | `references/ruliu-writing-tips.md` | 如流文档 JSON、append/cover、表格、图片、发布验证等经验 |
| 长手册 | `references/ku-doc-editing.md` | 原有完整实测手册 |
| 文档风格经验 | `references/ku-doc-writing/` | 产品/需求文档写作风格经验 |

## 明确剔除什么

| 内容 | 原因 |
|---|---|
| `private/` | 包含个人 token，不能分发 |
| `infoflow-message-group/` | 如流群机器人 AK/SK、发消息、群管理，不属于当前最小闭环 |
| `knowledge-fetch/` | knowbase 拉取知识源，本轮先不用 |
| `dumate-ent-info-sync/` | DuMate 企业版专项同步器，只抽取经验，不放进通用包 |

## 新电脑最短流程

1. 把 `ruliu-chat-docs` 文件夹放到：

```bash
$HOME/.codex/skills/ruliu-chat-docs
```

2. 让用户准备自己的邮箱前缀，例如 `zhangsan`。

3. 运行 UGate 缓存脚本：

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "zhangsan"
```

脚本会打开：

```text
https://uuap.baidu.com/agent/token
```

用户只需要在浏览器里复制页面里的 token，脚本会把 token 写到：

```text
~/.config/uuap/.eac_ugate_token_zhangsan
```

这个位置就是 `ku-darwin-arm64` 和企业内搜脚本读取 UGate 的地方。

如果浏览器还没有通过百度网关/SSO，先完成网关登录，刷新 token 页面再复制。如果 CLI 沙箱不能打开浏览器或读取剪贴板，使用：

```bash
bash "$HOME/.codex/skills/ruliu-chat-docs/scripts/cache-ugate-token.sh" "zhangsan" --stdin
```

然后把浏览器里复制的 token 粘贴进终端，按 `Ctrl-D`。

## 读取文档的一行命令

```bash
bash -lc 'export SANDBOX_USERNAME="zhangsan"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol markdown --show-doc-info'
```

读取编辑器 JSON：

```bash
bash -lc 'export SANDBOX_USERNAME="zhangsan"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; "$SKILL/deps/ku-doc-manage/bin/ku-darwin-arm64" query-content --url "https://ku.baidu-int.com/knowledge/..." --protocol json --show-doc-info'
```

## 编辑文档的基本原则

- 创建新文档可以直接传 Markdown。
- 新增内容默认用 `append`。
- 替换、删除、插入到中间，需要先读回 `protocol=json`，修改 JSON 后用 `cover`。
- `edit-content` 只写草稿，必须再运行 `publish-doc`。
- 写完要读回 markdown/json 验证。
- `protocol=markdown` 的正文在 `result.text`。
- `protocol=json` 的正文在 `result.content`。
- 评论不在正文 JSON 里，要用 `query-comments` 单独读取。

## 企业内搜一行命令

KU 文档搜索：

```bash
bash -lc 'export SANDBOX_USERNAME="zhangsan"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/ku_search.py --word "关键词" --page 1 --page-size 10'
```

普通内搜：

```bash
bash -lc 'export SANDBOX_USERNAME="zhangsan"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/neisou_search.py --word "关键词" --page 1 --page-size 10'
```

搜人：

```bash
bash -lc 'export SANDBOX_USERNAME="zhangsan"; SKILL="$HOME/.codex/skills/ruliu-chat-docs"; cd "$SKILL/deps/enterprise-search"; python3 scripts/address_search.py --type corpuser --q "姓名或邮箱前缀"'
```

## 附件

本文档附件中放置了本次挑出的最小 skill 包 zip。使用时解压后取里面的 `ruliu-chat-docs` 文件夹即可。
