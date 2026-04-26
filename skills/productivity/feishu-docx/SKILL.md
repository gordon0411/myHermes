---
name: feishu-docx
description: Create and write blocks to Feishu cloud documents (docx) via Feishu Open Platform API.
---
# Feishu Cloud Document (Docx) API

Write content to Feishu cloud documents using the Feishu Open Platform API.

## Authentication

Tenant access token from `.env` credentials:

```python
import urllib.request, json

with open('/mnt/d/GuojinX/xilu/.env') as f:
    for line in f:
        if line.startswith('FEISHU_APP_SECRET'):
            secret = line.split('=',1)[1].strip().strip('" ')

data = json.dumps({'app_id':'cli_a968e84c6878dbc4','app_secret':secret}).encode()
req = urllib.request.Request('https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal',
    data=data, headers={'Content-Type':'application/json'})
token = json.loads(urllib.request.urlopen(req).read())['tenant_access_token']
```

## Create a new document

```python
create_data = json.dumps({'title': 'Document Title'}).encode()
create_req = urllib.request.Request(
    'https://open.feishu.cn/open-apis/docx/v1/documents',
    data=create_data,
    headers={'Content-Type':'application/json', 'Authorization':'Bearer '+token}
)
doc = json.loads(urllib.request.urlopen(create_req).read())
doc_id = doc['data']['document']['document_id']
```

## Write blocks to document

Block types (block_type values):
- `2` = Text paragraph
- `3` = Heading 1
- `4` = Heading 2
- `5` = Heading 3
- `12` = Bullet list
- `13` = Ordered list
- `22` = Divider

Block structure — key matching rule:
```python
blocks = [
    {"block_type": 3, "heading1": {"elements": [{"type": "text_run", "text_run": {"content": "Title"}}], "style": {}}},
    {"block_type": 4, "heading2": {"elements": [{"type": "text_run", "text_run": {"content": "Section"}}], "style": {}}},
    {"block_type": 2, "text": {"elements": [{"type": "text_run", "text_run": {"content": "Body text"}}], "style": {}}},
    {"block_type": 12, "bullet": {"elements": [{"type": "text_run", "text_run": {"content": "List item"}}], "style": {}}},
]

insert_data = json.dumps({'children': blocks}).encode()
insert_req = urllib.request.Request(
    f'https://open.feishu.cn/open-apis/docx/v1/documents/{doc_id}/blocks/{doc_id}/children',
    data=insert_data,
    headers={'Content-Type':'application/json', 'Authorization':'Bearer '+token}
)
result = json.loads(urllib.request.urlopen(insert_req).read())
```

Document URL: `https://feishu.cn/docx/` + doc_id

## Reading Document Content

Use the `raw_content` endpoint to get full document text (simplest method):

```python
req = urllib.request.Request(
    f'https://open.feishu.cn/open-apis/docx/v1/documents/{doc_id}/raw_content',
    headers={'Authorization': 'Bearer ' + token}
)
result = json.loads(urllib.request.urlopen(req).read())
print(result['data']['content'])  # Full document text
```

Other approaches (avoid unless needed):
- `/blocks/{block_id}` - returns block metadata only, no text content
- `/blocks/{block_id}/children` - returns list of child block IDs, not text
- Block structure: block_type maps to key (3→heading1, 2→text, 12→bullet, etc.)

## Notes

- Max 50 blocks per request (write)
- Rate limit: 3 requests/second per app
- The block_type integer must match its named key (e.g., block_type 3 → "heading1", block_type 2 → "text")
- Initial write to a new doc requires using the doc_id as both document_id and block_id in the children endpoint
- **Reading tip**: Use `/raw_content` endpoint instead of traversing block tree
