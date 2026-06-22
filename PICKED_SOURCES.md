# 挑选来源和判断

## 本次输入来源

| 来源 | 路径 | 结论 |
|---|---|---|
| 当前 Codex skill | `/Users/pan/.codex/skills/ruliu-chat-docs` | 已能跑，含个人 `private/`，不能直接打包给新电脑用户 |
| 桌面版本 1 | `/Users/pan/Desktop/百度工作效率skill/ruliu-chat-docs` | 与当前 Codex 版本接近 |
| 桌面版本 2 | `/Users/pan/Desktop/百度工作效率skill/ruliu-chat-docs 2` | 与版本 1 接近，未发现比 final 更新的核心写入经验 |
| 桌面 final | `/Users/pan/Desktop/百度工作效率skill/ruliu-chat-docs final` | 信息最完整，作为最小包母版 |
| 官方 ku-doc-manage zip | `/Users/pan/Downloads/ku-doc-manage (1).zip` | 只有 wrapper 和说明，不带 `ku-darwin-arm64`，新电脑运行时会下载；本最小包改为直接带已下载二进制 |
| 官方 get-ugate-token zip | `/Users/pan/Downloads/get-ugate-token (1).zip` | 本质是读写 `~/.config/uuap/.eac_ugate_token_<uuap>`，保留作兜底参考 |
| 官方 knowledge-fetch zip | `/Users/pan/Downloads/knowledge-fetch (1).zip` | 本轮不需要，剔除 |
| 本地 memory 分析输出 | `/Users/pan/Documents/dumate_org_pro/gw_audit_memory_analysis` | 没找到比 skill 更具体的 KU 写入规则 |
| Dumate 企业信息同步 skill | `/Users/pan/.codex/skills/ruliu-chat-docs/deps/dumate-ent-info-sync` | 抽取表格、图片、发布验证、写入边界经验，不把项目同步器放进最小包 |

## 为什么最小包只保留三个 deps

| dep | 保留原因 |
|---|---|
| `ku-doc-manage` | KU 文档读、建、改、删、权限、评论、附件、表格等能力都在这里 |
| `enterprise-search` | 用户明确还需要内搜；它和 KU 一样依赖 UGate 缓存 |
| `get-ugate-token` | 官方缓存格式参考和兜底脚本 |

## 为什么剔除其他 deps

| dep | 剔除原因 |
|---|---|
| `infoflow-message-group` | 如流群机器人 AK/SK、发消息、群管理，不属于当前“KU 文档读取编辑 + 内搜”最小闭环 |
| `knowledge-fetch` | knowbase 拉取知识源，用户已经说先不用 |
| `dumate-ent-info-sync` | 是 DuMate 企业版专项同步器，不适合作为通用新电脑最小包 |
| `private/` | 包含个人 token，不能分发 |

## 最核心的一句话

新电脑真正需要的是：

```text
skill 文件夹 + ku-darwin-arm64 + ~/.config/uuap/.eac_ugate_token_<uuap>
```

其中 `~/.config/uuap/.eac_ugate_token_<uuap>` 由 `scripts/cache-ugate-token.sh` 生成。
