---
name: hermmes-vision-images
description: Use vision_analyze with local images - tool only accepts HTTP URLs, not local paths. Resize, serve via HTTP, then analyze.
---

# Hermes Vision Images Workflow

## The Problem

`vision_analyze` tool only accepts HTTP/HTTPS URLs. Local paths like `file://`, `d:\path`, `/mnt/path` all fail.

## Working Pipeline

**Step 1: Resize image** using Windows venv Python with PIL

```bash
"/mnt/d/GuojinX/xilu/venv/Scripts/python.exe" -c "from PIL import Image; img = Image.open(r'd:/GuojinX/xilu/cache/images/input.jpg'); img_small = img.resize((1400, 1590)); img_small.save(r'd:/GuojinX/xilu/cache/images/output_small.jpg', quality=85); print('done', img.size, '->', img_small.size)"
```

If PIL not installed first: `"/mnt/d/GuojinX/xilu/venv/Scripts/pip.exe" install pillow -q`

**Step 2: Serve image via HTTP**

```bash
cd /mnt/d/GuojinX/xilu/cache/images && python3 -m http.server 18999 &>/dev/null &
sleep 1
curl -s -o /dev/null -w "%{http_code}" http://localhost:18999/output_small.jpg
```

**Step 3: Use the HTTP URL with vision_analyze**

Navigate browser to `http://localhost:18999/output_small.jpg`, then call vision_analyze with that URL.

## Known Failures

- `file://` paths → "Invalid image source"
- Local Windows paths → "Invalid image source"
- `/mnt/*` Linux paths → "Invalid image source"
- Image upload services: catbox.moe (blocked), imgbb (no response), 0x0.st (disabled)
- WSL terminal commands may hang

## Key Paths

- Image cache: `/mnt/d/GuojinX/xilu/cache/images/`
- Windows venv: `/mnt/d/GuojinX/xilu/venv/Scripts/python.exe`
- Resize before analysis for large images (2800x3180 = ~1.2MB+)
