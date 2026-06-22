# 编辑文档正文

通过编辑操作列表对文档内容进行增删改操作，支持追加、覆盖两种操作模式。

## 请求参数

| 参数名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|--------|------|
| doc-id | string | 是 | - | 文档ID |
| username | string | 是 | - | 编辑者用户名（UUAP格式，即邮箱前缀，一般是当前用户名） |
| operations | list | 是 | - | 编辑操作列表（见下方说明） |
| publish | boolean | 否 | False | 是否编辑后同步发布 |

## operations 操作列表说明

每个操作是一个字典，包含以下字段：

| 字段 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| mode | string | 否 | `append` | 操作模式：`append`/`cover` |
| json | list | 是 | - | 编辑器 JSON 元素数组 |
| withNewCard | boolean | 否 | true | 是否使用新版卡片格式 |

### 操作模式说明

| mode | 说明 |
|------|------|
| `append` | 追加内容到文档末尾 |
| `cover` | 覆盖全文（完全替换文档所有内容） |

## json 元素格式说明

`json` 字段为编辑器节点数组，常用节点类型：

### 段落 (paragraph)
```json
{
    "type": "paragraph",
    "children": [
        {"type": "text", "text": "这是一段普通文字"}
    ]
}
```

### 标题 (heading)
```json
{
    "type": "heading",
    "level": 1,
    "children": [
        {"text": "分级标题一"}
    ]
}
```

### 有序列表 (orderedList)
```json
{
    "type": "ordered-list-item",
    "depth": 0,
    "index": 1,
    "children": [
        {"text": "11111"}
    ]
},
{
    "type": "ordered-list-item",
    "depth": 0,
    "index": 2,
    "children": [
        {"text": "222222"}
    ]
}
```

### 代码块 (codeBlock)
```json
{
    "type": "block-code",
    "language": "plain",
    "children": [
        {
            "type": "block-code-line",
            "children": [
                {"text": "这是是代码块"}
            ],
            "textIndent": 0,
            "textAlign": "left"
        }
    ]
}
```

### 图片（image）
```json
{
    "type": "image",
    "src": "https://bj.bcebos.com/ku-daas/storage/lw6JAMhc0YArEQ/cHfoPnbS1bH7Zu.png",
    "mimeType": "image/png",
    "invalid": false,
    "imageData": {
        "width": 480,
        "height": 82
    },
    "imageContainerData": {
        "x": 0,
        "y": 0,
        "width": 480,
        "height": 82
    },
    "width": 4626,
    "height": 790,
    "children": [
        {
            "text": ""
        }
    ]
}
```

### 附件（attachment）

> ⚠️ **重要**：添加附件需要两步操作，请先参考 [upload_attachment.md](upload_attachment.md) 上传附件获取 `fileId`。

**第一步：上传附件获取 fileId**
```bash
ku upload-attachment --doc-id WKoT7ltTnjU1oW --file /path/to/report.xlsx
```

响应返回：
```json
{
  "result": {
    "attachId": "f49c39d17cc24d34ae3fef0ebf295fe3",
    "name": "report.xlsx",
    "extension": "xlsx",
    "size": 3764
  }
}
```

**第二步：使用 attachId 作为 fileId 添加附件**
```json
{
    "type": "attachment",
    "fileId": "f49c39d17cc24d34ae3fef0ebf295fe3",
    "fileInfo": {
      "name": "report.xlsx",
      "size": 3764,
      "type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      "extension": "xlsx"
    },
    "viewType": "card",
    "invalid": false,
    "children": [
        {
            "text": ""
        }
    ],
    "docId": "eQgfKSA7NwuXSl",
    "id": "cxsrcjBT",
    "url": ""
}
```

**字段对应关系**：

| upload-attachment 响应字段 | attachment 参数 |
|---------------------------|-----------------|
| `attachId` | `fileId` |
| `name` | `fileInfo.name` |
| `size` | `fileInfo.size` |
| `extension` | `fileInfo.extension` |

**常见文件 MIME 类型**：
| 扩展名 | MIME type |
|--------|-----------|
| xlsx | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| xls | `application/vnd.ms-excel` |
| docx | `application/vnd.openxmlformats-officedocument.wordprocessingml.document` |
| doc | `application/msword` |
| pdf | `application/pdf` |
| jpeg | `image/jpeg` |
| 其他 | `application/octet-stream` |

### 表格 (table)
```json
{
    "type": "table",
    "sticky": false,
    "data": {
      "headless": true,
      "width": [
        74,
        74
      ]
    },
    "children": [
      {
        "type": "table-row",
        "children": [
          {
            "type": "table-cell",
            "children": [
              {
                "type": "paragraph",
                "children": [
                  {
                    "text": "行1"
                  }
                ]
              }
            ],
            "data": {
              "rowspan": 1,
              "colspan": 1
            }
          },
          {
            "type": "table-cell",
            "children": [
              {
                "type": "paragraph",
                "children": [
                  {
                    "text": "行2"
                  }
                ]
              }
            ],
            "data": {
              "rowspan": 1,
              "colspan": 1
            }
          }
        ]
      }
    ]
  }
```

## 响应示例

```json
{
    "returnCode": 200,
    "returnMessage": "OK",
    "result": {
        "docGuid": "WSuIrx09hfg6zr",
        "success": true,
        "operations": [
            {
                "success": true
            }
        ]
    },
    "traceId": "694507417572758528",
    "status": 200,
    "msg": "OK",
    "success": true
}
```

## CLI调用示例

```bash
# 示例1: 追加一段文字到文档末尾
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--operations '[{"mode":"append","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"追加的新内容"}]}]}]'

# 示例2: 覆盖全文（mode=cover 会完全替换文档内容，操作不可逆）
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--operations '[{"mode":"cover","withNewCard":true,"json":[{"type":"paragraph","children":[{"text":"新文档内容，完全替换原内容"}]}]}]'

# 示例3: 创建标题和段落
ku edit-content --doc-id WKoT7ltTnjU1oW --username zhangsan \
--operations '[{"mode":"append","withNewCard":true,"json":[{"type":"heading","level":1,"children":[{"text":"一级标题"}]},{"type":"paragraph","children":[{"text":"段落内容"}]}]}]'
```

## 注意事项

- `username` 必须是有权限编辑该文档的用户
- `cover` 模式会清空文档所有内容后重写，操作不可逆，请谨慎使用
- 默认 `publish=False`，编辑完成后为草稿状态；若需要自动发布，设为 `True`