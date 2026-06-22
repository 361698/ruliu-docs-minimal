# KU 文档插入多模态内容经验手册

本文记录在 `ku-doc-manage` 中向如流知识库普通文档插入多种内容的可复用方式。重点来自 2026-06-08 实测：图片、表格内图片、源文档图片搬运、HTML demo 截图、附件卡片均已跑通。

> 适用对象：`ku.baidu-int.com` 普通文档。在线表格、数据表不是普通文档，不能用这里的 `edit-content` JSON 方式直接改单元格。

## 总流程

1. 解析目标文档 URL，取最后一段为 `doc-id`。
2. 用当前用户确认权限。
3. 准备要插入的编辑器 JSON 节点。
4. 如需图片或附件，先 `upload-attachment` 上传到目标文档。
5. 用 `edit-content --editor-mode append --operations ...` 追加（此时只是草稿）。
6. 用 `publish-doc --doc-id ... --username ...` 发布草稿（该子命令在 `ku --help` 中不显示，但存在）。
7. 用 `query-content --protocol json` 读回验证节点是否存在。

基础命令：

```bash
export KU="$HOME/.codex/skills/ku-doc-manage/bin/ku"
export USERNAME="<current-uuap>"
export DOC_ID="<target-doc-guid>"

"$KU" query-content --doc-id "$DOC_ID" --protocol json --show-doc-info
```

## 编辑工具与定位策略

### 用什么工具编辑

编辑普通 KU 文档正文用：

```bash
"$KU" edit-content
```

它是 `ku-doc-manage` skill 封装的 CLI，底层调用 KU OpenAPI 的 `editContent` 能力。

常用完整命令：

```bash
"$KU" edit-content \
  --doc-id "$DOC_ID" \
  --username "$USERNAME" \
  --editor-mode append \
  --operations "$OPS_JSON"

# 编辑后必须单独发布（edit-content 没有 --publish 参数，编辑结果是草稿）
"$KU" publish-doc --doc-id "$DOC_ID" --username "$USERNAME"
```

必要参数：

- `--doc-id`：目标文档 ID。
- `--username`：编辑者 UUAP，例如当前用户邮箱前缀。
- `--operations`：编辑操作 JSON 数组。

注意：CLI 没有 `--publish` 参数（API 层的 `publish` 字段未透出），编辑后停留在草稿态，必须再跑 `publish-doc` 才会发布。

### URL 怎么定位到文档

普通文档 URL 格式：

```text
https://ku.baidu-int.com/knowledge/<spaceGuid>/<groupGuid>/<repositoryGuid>/<docGuid>
```

定位规则：

- 最后一段是 `docGuid`，也就是 `--doc-id`。
- 倒数第二段是 `repositoryGuid`，创建新文档或查知识库列表时会用到。

示例：

```text
https://ku.baidu-int.com/knowledge/HFVrC7hq1Q/pKzJfZczuc/_qWLcaIqoR/RfzeUYBUPeYN3m
```

对应：

```text
doc-id = RfzeUYBUPeYN3m
repositoryGuid = _qWLcaIqoR
```

### append 还是 cover

`edit-content` 主要有两种安全等级不同的模式：

| 模式 | 含义 | 推荐场景 | 风险 |
|---|---|---|---|
| `append` | 追加到文档末尾 | 新增小节、新增表格、新增图片汇总 | 不能精确插到中间 |
| `cover` | 覆盖全文 | 已读回全文 JSON，并准备完整重写文档 | 会替换整篇文档，风险高 |

日常默认用 `append`。这次插入表格、图片、HTML 截图都是追加到文档末尾的新小节。

不要为了“插入到中间”直接用 `cover`，除非已经完整备份并重组了全文 JSON。

### operations 结构

`--operations` 是一个数组，每个元素是一次操作：

```json
[
  {
    "mode": "append",
    "withNewCard": true,
    "json": [
      {
        "type": "heading",
        "level": 2,
        "children": [{"text": "新增小节"}]
      },
      {
        "type": "paragraph",
        "children": [{"text": "新增内容"}]
      }
    ]
  }
]
```

### 怎么定位到指定位置

当前 CLI 文档明确支持 `append` 和 `cover`。没有稳定暴露“按 blockId 插入到某个块前后”的参数。

因此有三种策略：

1. **新增内容**：用 `append` 追加到文档末尾。最安全。
2. **替换整篇**：先 `query-content --protocol json` 读回全文，修改 JSON，再用 `cover` 覆盖全文。高风险，必须备份。
3. **需要插到中间**：先读回 JSON，找到锚点文字或 `blockId`，在本地重组全文内容，然后 `cover`。这本质上仍是全文覆盖。

锚点定位伪代码：

```python
def find_node_by_text(node, needle):
    if isinstance(node, dict):
        text = "".join(
            child.get("text", "")
            for child in node.get("children", [])
            if isinstance(child, dict)
        )
        if needle in text:
            return node
        for value in node.values():
            found = find_node_by_text(value, needle)
            if found:
                return found
    elif isinstance(node, list):
        for item in node:
            found = find_node_by_text(item, needle)
            if found:
                return found
```

覆盖前必须做：

```bash
"$KU" query-content --doc-id "$DOC_ID" --protocol json > "/tmp/${DOC_ID}.backup.json"
```

建议只有在用户明确要求“插到某个标题下面/替换某段”时才考虑 `cover`，并在本地保存备份。

`query-content --protocol json` 读回的 `result.content[0]` 通常是文档标题节点。用 `cover` 重写正文时，不要把这个标题节点放进 `operations[0].json`，否则标题可能被重复写进正文。只写回正文 card / card-item 结构，并保留未改动的图片、附件、流程图、引用等节点。

如果用户要求“替换原文对应部分”，不要用追加“生效口径”小节糊过去。必须读回 JSON，定位目标段落、表格行或 card，修改对应节点后 `cover` 写回，再用 markdown/json 双读回确认旧词已经消失、新词出现在原位置。

追加内容模板：

```bash
"$KU" edit-content \
  --doc-id "$DOC_ID" \
  --username "$USERNAME" \
  --editor-mode append \
  --operations '[{"mode":"append","withNewCard":true,"json":[...]}]'

"$KU" publish-doc --doc-id "$DOC_ID" --username "$USERNAME"
```

## 已验证能力矩阵

| 模态 | 是否验证 | 推荐方式 | 关键点 |
|---|---:|---|---|
| 段落/标题 | 已验证 | `paragraph` / `heading` 节点 | `children` 里放 `{"text":"..."}` |
| 加粗/斜体 | 已观测并可按样本写入 | text leaf 上加 `bold:true` / `italic:true` | 源文档 JSON 中已出现；建议写后读回 |
| 下划线/删除线 | 待小样本验证 | text leaf 上尝试 `underline:true` / `strikethrough:true` | 工具栏支持，当前样本未覆盖 |
| 无序列表/有序列表 | 已观测结构 | `unordered-list-item` / `ordered-list-item` | `depth` 控制缩进，`index` 控制编号 |
| 表格 | 已验证 | `table` / `table-row` / `table-cell` | `table.data.width` 控制列宽；单元格 children 可放段落、图片、附件 |
| 表头灰底 | 已观测结构 | 首行每个 `table-cell.data.backgroundColor` | 源文档中已观测到灰底单元格 |
| 表格内图片 | 已验证 | 先上传图片，再放 `image` 节点 | `src` 用目标文档的 `imageDownloadAddress` |
| 搬运其他 KU 文档图片 | 已验证 | 读取源文档图片节点，下载，上传到目标文档，再插入 | 不建议直接复用源文档 `src` |
| 本地 HTML demo 截图 | 已验证 | 临时启动 `127.0.0.1` 服务，浏览器截图，上传 PNG，再插入 | 不要用 `file://`，会被浏览器安全策略拦截 |
| 附件卡片 | 已验证 | `upload-attachment` + `attachment` 节点 | HTML/JS/Excel/PDF 等适合附件卡片 |
| 链接 | 观测到结构 | `link` 节点 | 已在源文档 JSON 观测，建议小样本验证 |
| Mermaid | 观测到结构 | `block-code` + `language:"mermaid"` | 源文档里以代码块存储，不一定自动渲染成图 |
| @ 人 | 待验证 | 先 `query-user-info` / 企业搜索取用户信息，再找样本文档结构 | 不要臆造 mention 节点 |

## 常用节点模板

### 空白规范

写入 KU 文档前先做空白清洗，避免内容间距过宽：

- 不要在正文里连续写两个普通空格。
- 中文段落内部不要用空格制造视觉间隔，改用标点、换行、列表或表格列。
- 英文和数字之间保留必要单空格即可。
- JSON 里的缩进空格不影响正文；只需要清洗 `text` 字段里的文本。
- 如果要制造段落间距，插入新的 `paragraph` 节点，不要在同一段里塞多个空格或空行。

推荐清洗函数：

```python
import re

def clean_text(text: str) -> str:
    text = text.replace("\u00a0", " ")
    text = re.sub(r"[ \t]{2,}", " ", text)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()
```

### 标题和段落

```json
[
  {
    "type": "heading",
    "level": 2,
    "children": [{"text": "二级标题"}]
  },
  {
    "type": "paragraph",
    "children": [{"text": "普通正文"}]
  }
]
```

### 文本样式

加粗、斜体这类样式直接写在文字 leaf 上。

```json
{
  "type": "paragraph",
  "children": [
    {"text": "这是普通文字，"},
    {"text": "这是加粗文字", "bold": true},
    {"text": "，"},
    {"text": "这是斜体文字", "italic": true},
    {"text": "，"},
    {"text": "这是加粗斜体", "bold": true, "italic": true}
  ]
}
```

从已读回文档中观测到的样式字段：

```json
{"text": "规则分组", "bold": true, "font-color": "rgb(31, 31, 31)"}
{"text": "强调文字", "bold": true, "italic": true}
```

下划线和删除线在工具栏上存在，但本次样本文档没有稳定 JSON 样本。可先在临时样本文档小样本确认：

```json
{
  "type": "paragraph",
  "children": [
    {"text": "下划线", "underline": true},
    {"text": "，"},
    {"text": "删除线", "strikethrough": true}
  ]
}
```

验证方式：写入后 `query-content --protocol json`，确认字段是否被保留，并在 KU 页面确认 UI 是否正确展示。

### 列表和标题编号

真正的标题用 `heading` 节点，不要把 `1. 标题` 当成普通段落硬写。

```json
{
  "type": "heading",
  "level": 2,
  "children": [{"text": "1. 购买流程"}]
}
```

无序列表对应工具栏里的 `·`：

```json
{
  "type": "unordered-list-item",
  "depth": 0,
  "children": [{"text": "第一条要点"}]
}
```

有序列表对应工具栏里的 `1.`：

```json
[
  {
    "type": "ordered-list-item",
    "depth": 0,
    "index": 1,
    "children": [{"text": "第一步"}]
  },
  {
    "type": "ordered-list-item",
    "depth": 0,
    "index": 2,
    "children": [{"text": "第二步"}]
  }
]
```

嵌套列表用 `depth`：

```json
[
  {
    "type": "unordered-list-item",
    "depth": 0,
    "children": [{"text": "一级要点"}]
  },
  {
    "type": "unordered-list-item",
    "depth": 1,
    "children": [{"text": "二级要点"}]
  }
]
```

### 表格

```json
{
  "type": "table",
  "sticky": false,
  "data": {
    "headless": false,
    "width": [80, 240, 520]
  },
  "children": [
    {
      "type": "table-row",
      "children": [
        {
          "type": "table-cell",
          "children": [{"type": "paragraph", "children": [{"text": "序号"}]}],
          "data": {"rowspan": 1, "colspan": 1}
        },
        {
          "type": "table-cell",
          "children": [{"type": "paragraph", "children": [{"text": "名称"}]}],
          "data": {"rowspan": 1, "colspan": 1}
        },
        {
          "type": "table-cell",
          "children": [{"type": "paragraph", "children": [{"text": "内容"}]}],
          "data": {"rowspan": 1, "colspan": 1}
        }
      ]
    }
  ]
}
```

### 表格宽度和表头灰底

列宽由 `table.data.width` 控制，数组里的每个数字对应一列宽度。单位可理解为编辑器内部的像素宽度。

```json
{
  "type": "table",
  "sticky": false,
  "data": {
    "headless": false,
    "width": [80, 220, 520]
  },
  "children": []
}
```

建议：

- 窄列如序号：`60` 到 `90`。
- 文本列：`180` 到 `320`。
- 图片列：`520` 到 `820`，同时控制图片 `imageData.width`，否则图片可能撑开阅读体验。
- `headless:false` 表示有表头；`headless:true` 更像普通无表头表格。

首行置灰通过每个表头单元格的 `data.backgroundColor` 设置。源文档里观测到的灰色为 `rgb(231, 230, 230)`，也可以用更浅的 `rgb(248, 248, 248)`。

表头单元格模板：

```json
{
  "type": "table-cell",
  "children": [
    {
      "type": "paragraph",
      "children": [
        {"text": "表头", "bold": true}
      ]
    }
  ],
  "data": {
    "rowspan": 1,
    "colspan": 1,
    "backgroundColor": "rgb(231, 230, 230)",
    "borderColor": "rgb(191, 191, 191)",
    "borderIndex": 1
  }
}
```

完整 3 列表头行示例：

```json
{
  "type": "table-row",
  "children": [
    {
      "type": "table-cell",
      "children": [{"type": "paragraph", "children": [{"text": "序号", "bold": true}]}],
      "data": {"rowspan": 1, "colspan": 1, "backgroundColor": "rgb(231, 230, 230)"}
    },
    {
      "type": "table-cell",
      "children": [{"type": "paragraph", "children": [{"text": "名称", "bold": true}]}],
      "data": {"rowspan": 1, "colspan": 1, "backgroundColor": "rgb(231, 230, 230)"}
    },
    {
      "type": "table-cell",
      "children": [{"type": "paragraph", "children": [{"text": "内容", "bold": true}]}],
      "data": {"rowspan": 1, "colspan": 1, "backgroundColor": "rgb(231, 230, 230)"}
    }
  ]
}
```

注意：

- 灰底是单元格级设置，不是 `table.data` 的全局字段。
- 如果只给文字 leaf 设置 `bg-color`，通常是文字背景，不是整个单元格背景。
- 写入后读回时检查 `table-cell.data.backgroundColor` 是否保留。

## 图片插入

### 1. 上传本地图片

```bash
"$KU" upload-attachment \
  --doc-id "$DOC_ID" \
  --file "/absolute/path/to/image.png"
```

返回里取：

```json
{
  "result": {
    "attachId": "36b0264f8c084bddad4a5addb810fcf0",
    "docGuid": "<target-doc-guid>",
    "extension": "png",
    "name": "image.png",
    "size": 126623
  }
}
```

图片节点的 `src` 用这个格式：

```text
https://rte.weiyun.baidu.com/wiki/attach/image/api/imageDownloadAddress?attachId=<attachId>&docGuid=<target-doc-guid>
```

### 2. 图片节点

```json
{
  "type": "image",
  "src": "https://rte.weiyun.baidu.com/wiki/attach/image/api/imageDownloadAddress?attachId=<attachId>&docGuid=<target-doc-guid>",
  "mimeType": "image/png",
  "invalid": false,
  "imageData": {"width": 480, "height": 240},
  "imageContainerData": {"x": 0, "y": 0, "width": 480, "height": 240},
  "width": 1280,
  "height": 640,
  "children": [{"text": ""}]
}
```

说明：

- `width` / `height` 建议填原图尺寸。
- `imageData` / `imageContainerData` 建议填文档内展示尺寸。
- 表格单元格里也可以直接把这个 `image` 节点放到 `table-cell.children`。

### 3. 表格内图片实测模板

```json
{
  "type": "table-cell",
  "children": [
    {
      "type": "image",
      "src": "https://rte.weiyun.baidu.com/wiki/attach/image/api/imageDownloadAddress?attachId=<attachId>&docGuid=<target-doc-guid>",
      "mimeType": "image/png",
      "invalid": false,
      "imageData": {"width": 520, "height": 211},
      "imageContainerData": {"x": 0, "y": 0, "width": 520, "height": 211},
      "width": 1132,
      "height": 460,
      "children": [{"text": ""}]
    }
  ],
  "data": {"rowspan": 1, "colspan": 1}
}
```

## 搬运另一个 KU 文档里的所有图片

实测策略：

1. `query-content --protocol json` 读取源文档。
2. 遍历所有 `{"type":"image","src":...}` 节点。
3. 从 `src` 中提取源 `attachId`，按 `attachId` 去重下载。
4. 每张图片上传到目标文档，得到新的目标 `attachId`。
5. 生成目标文档自己的 `imageDownloadAddress`。
6. 按源文档出现顺序插入表格；重复出现的图片可以复用同一个目标 `attachId`。

不要直接把源文档的 `src` 放到目标文档里。跨文档图片链接可能受权限、过期签名或附件归属影响，稳定性不如重新上传到目标文档。

Python 伪代码：

```python
def collect_images(node, images):
    if isinstance(node, dict):
        if node.get("type") == "image" and node.get("src"):
            images.append(node)
        for value in node.values():
            collect_images(value, images)
    elif isinstance(node, list):
        for item in node:
            collect_images(item, images)
```

## HTML demo 截图插入

这次踩坑：直接打开本地 `file://.../index.html` 被浏览器安全策略拦截，不能截图。

已验证方案：

1. 在 HTML 目录启动临时本地服务。

```bash
cd "/path/to/html/demo"
python3 -m http.server 8765 --bind 127.0.0.1
```

2. 用浏览器打开 `http://127.0.0.1:8765/index.html`。
3. 对每个 HTML 页面截图，保存为 PNG。
4. 用 `upload-attachment` 上传 PNG。
5. 作为 `image` 节点插入表格。
6. 完成后停止临时服务。

注意：

- 如果某个页面依赖登录态或脚本跳转，截图可能不是原始页面。例如本次 `purchase.html` 渲染时命中登录态，需要在表格说明里标注。
- 截图用于在 KU 表格里直接展示；HTML 原文件可另外用附件卡片保存，方便追溯。

## 附件卡片

适合插入 HTML、JS、PDF、Excel、ZIP 等文件。

### 1. 上传附件

```bash
"$KU" upload-attachment --doc-id "$DOC_ID" --file "/absolute/path/to/file.html"
```

### 2. 附件节点

```json
{
  "type": "attachment",
  "fileId": "<attachId>",
  "fileInfo": {
    "name": "index.html",
    "size": 24472,
    "type": "text/html",
    "extension": "html"
  },
  "viewType": "card",
  "invalid": false,
  "children": [{"text": ""}],
  "docId": "<target-doc-guid>",
  "id": "att12345678",
  "url": ""
}
```

注意：附件卡片不是图片。用户要“截图”时，必须把 HTML 渲染成 PNG/JPG 后插入 `image` 节点。

## 链接

从已有 KU 文档中观测到的链接节点结构：

```json
{
  "type": "link",
  "href": "https://example.com",
  "title": "Example",
  "id": "uuid-like-id",
  "children": [
    {
      "text": "Example",
      "font-color": "#1C1D1F"
    }
  ]
}
```

建议放在段落 children 中：

```json
{
  "type": "paragraph",
  "children": [
    {"text": "参考链接："},
    {
      "type": "link",
      "href": "https://example.com",
      "title": "Example",
      "id": "link-001",
      "children": [{"text": "Example"}]
    }
  ]
}
```

状态：已在源文档 JSON 观测到结构，但尚未单独做“写入后 UI 可点击”的小样本确认。正式批量写入前建议先在临时样本文档追加一个链接并读回确认。

## Markdown 和 Mermaid

### 创建文档和 Markdown

`create-doc` 支持 `--content` 或 `--md-file`，并可自动处理 Markdown 图片；但不要把它当作稳定正文写入路径。实测中创建接口可能把正文放到 title 节点的 `markdown.content` 元数据里，而不是可见正文区。创建带正文的普通文档时，优先创建空文档拿 `docGuid`，然后用 `edit-content append` 写正文、`publish-doc` 发布、再读回确认。

```bash
"$KU" create-doc \
  --repo-id "<repo-guid>" \
  --username "$USERNAME" \
  --title "带 Markdown 的文档" \
  --create-mode empty
```

如果 Markdown 里有本地图片，先上传图片并按目标文档的 `attachId` 生成 image 节点；不要直接依赖创建接口处理复杂正文。

### 编辑已有文档时插入 Mermaid

从已有 KU 文档中观测到 Mermaid 以代码块形式存储：

```json
{
  "type": "block-code",
  "language": "mermaid",
  "view": "split",
  "autowrap": true,
  "children": [
    {
      "type": "block-code-line",
      "children": [{"text": "flowchart TD"}],
      "textIndent": 0,
      "textAlign": "left"
    },
    {
      "type": "block-code-line",
      "children": [{"text": "    A[Start] --> B[End]"}],
      "textIndent": 0,
      "textAlign": "left"
    }
  ]
}
```

状态：源文档中已观测到 `language:"mermaid"` 的 `block-code`，但这更像“Mermaid 代码块”，不保证直接渲染成流程图卡片。若用户需要可视化图，建议优先截图或导出为图片再用 `image` 节点插入。

## @ 人

正文里 `@人` 的编辑器 JSON 结构已经在 2026-06-08 的源文档 JSON 中观测到。常规同步仍不应把源文档里的 @ 人机械复制成通知；只在用户明确要求或事实变化需要确认时，生成目标人。

保守做法：

1. 先用企业搜索或 KU 用户接口确认用户：

```bash
"$KU" query-user-info --username "<uuap>"
```

2. 找一个已包含 @ 人的样本文档，`query-content --protocol json` 观察真实 mention 节点。
3. 只按真实样本写入。

已观测到的 contact mention 节点关键字段：

```json
{
  "type": "mention",
  "mentionType": "contact",
  "mentionId": "xL93lXnRwh",
  "mentionName": "张三",
  "mentionSubtitle": "zhangsan@baidu.com",
  "mentionDescription": "示例部门",
  "mentionAvatar": "https://ku.baidu-int.com/wiki/ku/users/avatar?userGuid=xL93lXnRwh",
  "mentionToken": "",
  "messageId": "huangyuruicam",
  "canReplyComment": false,
  "children": [{"text": ""}]
}
```

批量同步或改写他人文档时，建议采用更保守的受控标记：只有用户明确要求的标记才转换为真实 mention；普通 `@姓名` 默认先按纯文本处理，避免误通知。

如果只是文本提示，可以先写纯文本：

```json
{
  "type": "paragraph",
  "children": [{"text": "@zhangsan 请确认"}]
}
```

但纯文本不会触发真正的人员卡片或通知。

## 验证清单

写入后至少做一次读回：

```bash
"$KU" query-content --doc-id "$DOC_ID" --protocol json > /tmp/ku_after.json
```

建议检查：

- 新标题是否存在。
- 表格行数是否符合预期。
- `table.data.width` 是否符合预期列宽。
- 表头单元格是否保留 `data.backgroundColor`。
- 图片节点数量是否符合预期。
- 图片 `src` 是否使用目标文档 `docGuid`。
- 附件节点 `fileInfo.name` 是否符合预期。
- `text` 字段里是否还存在连续两个普通空格。
- 加粗、列表、标题等格式字段是否被读回保留。
- `edit-content` 返回 `operations[].success == true`。

## 实测结论

- 普通文档可以通过 `edit-content` 插入表格，表格单元格内可以放图片。
- 表格列宽通过 `table.data.width` 控制；表头灰底通过首行各 `table-cell.data.backgroundColor` 控制。
- 图片最好上传到目标文档后，用目标文档的 `imageDownloadAddress` 插入。
- 从其他 KU 文档搬运图片时，应下载并重新上传到目标文档。
- HTML demo 截图不要用 `file://`，改用临时 `127.0.0.1` 本地服务渲染后截图。
- 附件卡片能保存原文件，但不是可见截图。
- 加粗、斜体、标题、有序列表、无序列表都可以通过编辑器 JSON 表达；下划线和删除线需要小样本确认字段名。
- 插入内容前必须清洗正文文本，避免连续两个普通空格造成展示间距过宽。
- Mermaid 和 @ 人需要进一步小样本验证，不能只凭猜测批量写入。
