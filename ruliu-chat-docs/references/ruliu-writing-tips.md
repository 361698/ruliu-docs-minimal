# 如流 KU 文档写入技巧汇总

这份是从当前本地记忆、当前 Codex skill、桌面几个 `ruliu-chat-docs` 版本、`ku-doc-manage` 官方说明、`dumate-ent-info-sync` 项目经验里挑出来的可复用规则。

## 来源结论

- 本地 `gw_audit_memory_analysis` 里没有找到比当前 skill 更具体的 KU 写入技巧，主要是用户任务日志和泛工作流。
- 当前 `~/.codex/skills/ruliu-chat-docs` 和桌面 `ruliu-chat-docs final` 的核心技巧基本一致。
- `ruliu-chat-docs final` 多了认证引导和能力映射，但如流文档写入经验主要仍在 `references/ku-doc-editing.md`、`references/ku-doc-writing/README.md`。
- `dumate-ent-info-sync` 提供了大量实战经验：表格列宽、表头灰底、图片插入表格、发布后回读、避免误覆盖等。

## 读写模型

KU 普通文档可以被表达为编辑器 JSON。读取时：

- `protocol=markdown`：返回 JSON 外壳，但正文在 `result.text`，是 Markdown 字符串。
- `protocol=json`：正文在 `result.content`，是编辑器 JSON 数组。
- `result.docInfo`：文档标题、创建者、发布时间、知识库等元数据。
- 评论不在正文 JSON 中，必须用 `query-comments` 单独读取。

写入时：

- 创建文档可以直接传 Markdown 或 `--md-file`。
- 编辑已有普通文档正文使用 `edit-content --operations '<JSON数组>'`。
- `append` 是追加到末尾，最安全。
- `cover` 是覆盖正文，能做替换、删除、中间插入，但必须先读回 JSON 并备份。
- `edit-content` 只保存草稿，必须再运行 `publish-doc`。

## append 和 cover 的边界

默认用 `append`：

- 新增小节。
- 追加表格。
- 追加图片或附件说明。
- 给文档末尾补充一段总结。

必须考虑 `cover`：

- 用户要求替换原文某段。
- 用户要求删除某段。
- 用户要求插入到某个标题下面。
- 用户要求修改表格里的某一行或某个单元格。

`cover` 的基本流程：

1. `query-content --protocol json` 读取。
2. 保存备份到本地。
3. 遍历 JSON，通过文字锚点、表格行文本或 `blockId` 定位。
4. 修改目标节点，保留无关节点。
5. `edit-content --editor-mode cover` 写回。
6. `publish-doc` 发布。
7. 再用 markdown/json 双读回验证。

注意：`result.content[0]` 通常是 `title` 节点。覆盖正文时不要把标题节点放进正文 payload，否则标题可能在正文里重复出现。

## 常用编辑器 JSON 节点

段落：

```json
{"type":"paragraph","children":[{"text":"普通正文"}]}
```

标题：

```json
{"type":"heading","level":2,"children":[{"text":"二级标题"}]}
```

加粗和斜体：

```json
{"type":"paragraph","children":[{"text":"普通，"},{"text":"加粗","bold":true},{"text":"，"},{"text":"斜体","italic":true}]}
```

无序列表：

```json
{"type":"unordered-list-item","depth":0,"children":[{"text":"第一条"}]}
```

有序列表：

```json
{"type":"ordered-list-item","depth":0,"index":1,"children":[{"text":"第一步"}]}
```

代码块：

```json
{"type":"block-code","language":"plain","children":[{"type":"block-code-line","children":[{"text":"code"}],"textIndent":0,"textAlign":"left"}]}
```

## 表格技巧

表格要写成 KU `table` 节点，不要退化成代码块。

列宽：

- `table.data.width` 控制每列宽度。
- 总宽建议约 `1260`。
- 单列不要低于 `90`。
- 序号列通常 `60-90`。
- 普通文本列通常 `180-320`。
- 图片列通常 `520-820`，同时控制图片展示宽度。

表头：

- `headless:false` 只表示有表头，不等于自动灰底。
- 首行每个 `table-cell.data.backgroundColor` 写 `rgb(231, 230, 230)`。
- 建议同时带 `borderColor:"rgb(191, 191, 191)"` 和 `borderIndex:1`。

Markdown 表格写作：

- 每行列数必须一致。
- 空单元格统一写 `-`，不要留空。
- 行尾不要出现紧贴的 `||`。
- 相邻行如果第一列分组重复，除首行外可写 `-`，降低视觉重复。
- 不要出现 `备注 | 备注 | ...` 这种无信息重复列，改成 `概要`、`标题` 或更具体字段。

## 图片和附件

插入图片要先上传：

```bash
ku upload-attachment --doc-id "<docGuid>" --file "/absolute/path/to/image.png"
```

然后用返回的 `attachId` 生成图片地址：

```text
https://rte.weiyun.baidu.com/wiki/attach/image/api/imageDownloadAddress?attachId=<attachId>&docGuid=<docGuid>
```

图片节点要设置：

- `src`
- `mimeType`
- `imageData.width/height`
- `imageContainerData.width/height`
- 原始 `width/height`

跨文档搬运图片时，不要直接复用源文档图片 URL。更稳妥的方式是下载源图、上传到目标文档、再插入目标文档自己的图片地址。

HTML demo 要先渲染成图片：

1. 用 `python3 -m http.server` 起本地服务。
2. 用浏览器/Playwright 截图。
3. 上传 PNG。
4. 作为 KU `image` 节点插入。

HTML、Excel、PDF、ZIP 更适合插成 `attachment` 卡片，不是图片。

## 文档写作风格

产品/需求类文档优先做到：

- 只写能帮助决策的信息，不为了像 PRD 而堆章节。
- 分清“已确定”和“待讨论”。
- 结论先行，但结论要像判断句，不要只是标签。
- 表格列数跟问题复杂度匹配，能三列讲清楚就不要扩成六列。
- 先定义口径，再放推算。
- 用产品文档语气：直接、可判断、不过度口语。

常用结构：

- 背景
- 目标
- 方案
- 关键规则
- 待讨论

如果信息量不够，不要硬补竞品、指标、风险、流程。

## 发布后检查

写完必须读回：

```bash
ku query-content --doc-id "<docGuid>" --protocol markdown --show-doc-info
ku query-content --doc-id "<docGuid>" --protocol json --show-doc-info
```

检查：

- `edit-content` 是否返回成功。
- `publish-doc` 是否执行。
- Markdown 里新内容是否可见。
- JSON 里表格是否是 `table/table-row/table-cell`。
- `table.data.width` 是否合理。
- 表头灰底是否保留在 `table-cell.data.backgroundColor`。
- 图片是否在目标文档下有新的 `attachId`。
- 如果是替换，旧词是否已经消失。

## 安全边界

- 不把 UGate token、Bearer token、AK/SK 写入文档或聊天。
- 不把 `private/` 打包给别人。
- 删除文档前必须二次确认。
- 对源文档做同步类任务时，只写明确允许的目标文档。
- 不确定是否事实变更时，写入“待确认”，不要直接改成结论。
