# PowerPoint 處理 recipe

套件：`python-pptx`、`pillow`（圖片）

---

## P0. 用既有範本前先印出版面配置

不同範本的 `slide_layouts` 索引完全不同，**不要背 0/1/5/6**，先印出來看：

```python
# -*- coding: utf-8 -*-
from pptx import Presentation

presentation = Presentation("校內範本.pptx")
for index, layout in enumerate(presentation.slide_layouts):
    names = [f"{p.placeholder_format.idx}:{p.name}" for p in layout.placeholders]
    print(index, layout.name, names)
```

沒有範本時 `Presentation()` 的預設版面：`0` 標題投影片、`1` 標題及內容、`5` 僅標題、`6` 空白。

---

## P1. 教材大綱 → 整份簡報

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from pptx import Presentation
from pptx.util import Pt

OUTLINE = [
    ("光合作用", ["發生位置：葉綠體", "原料：二氧化碳與水", "產物：葡萄糖與氧氣"]),
    ("呼吸作用", ["發生位置：粒線體", "與光合作用的差異"]),
]

presentation = Presentation("校內範本.pptx")      # 沒有範本就 Presentation()
title_layout = presentation.slide_layouts[0]
content_layout = presentation.slide_layouts[1]

cover = presentation.slides.add_slide(title_layout)
cover.shapes.title.text = "第三章 植物的養分"
if len(cover.placeholders) > 1:
    cover.placeholders[1].text = "自然領域　七年級"

for heading, bullets in OUTLINE:
    slide = presentation.slides.add_slide(content_layout)
    slide.shapes.title.text = heading
    body = slide.placeholders[1].text_frame
    body.text = bullets[0]
    for bullet in bullets[1:]:
        paragraph = body.add_paragraph()
        paragraph.text = bullet
        paragraph.level = 0
    for paragraph in body.paragraphs:            # 字級太小老師會抱怨
        for run in paragraph.runs:
            run.font.size = Pt(24)

Path("output").mkdir(exist_ok=True)
presentation.save("output/植物的養分.pptx")
```

**陷阱**：用範本 `add_slide` 出來的頁面會沿用範本的佔位符，但**範本原有的投影片還在**。
若使用者只要新頁面，請他提供「只有母片、沒有內容頁」的範本，或處理完手動刪除前幾頁。

---

## P2. 圖片資料夾 → 圖卡簡報

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from pptx import Presentation
from pptx.util import Inches, Pt
from PIL import Image

SUFFIXES = {".jpg", ".jpeg", ".png", ".webp"}

presentation = Presentation()
presentation.slide_width = Inches(13.333)        # 16:9
presentation.slide_height = Inches(7.5)
blank = presentation.slide_layouts[6]

slide_width = presentation.slide_width
slide_height = presentation.slide_height
caption_height = Inches(0.9)

for image_path in sorted(p for p in Path("圖片").iterdir() if p.suffix.lower() in SUFFIXES):
    with Image.open(image_path) as image:
        image_ratio = image.width / image.height

    box_width = slide_width - Inches(1)
    box_height = slide_height - caption_height - Inches(1)
    if box_width / box_height > image_ratio:      # 等比縮放置中，不要變形
        height = box_height
        width = int(height * image_ratio)
    else:
        width = box_width
        height = int(width / image_ratio)

    slide = presentation.slides.add_slide(blank)
    slide.shapes.add_picture(
        str(image_path),
        int((slide_width - width) / 2),
        int((slide_height - caption_height - height) / 2),
        width=width, height=height,
    )
    textbox = slide.shapes.add_textbox(0, slide_height - caption_height, slide_width, caption_height)
    frame = textbox.text_frame
    frame.text = image_path.stem
    frame.paragraphs[0].runs[0].font.size = Pt(28)

presentation.save("output/圖卡.pptx")
```

---

## P3. 全簡報統一字型／每頁加校徽

**中文字型的陷阱**：只設 `run.font.name` 只會改到 latin 字型，中文字仍然是舊字體。
必須連 `a:ea`（東亞字型）一起設：

```python
# -*- coding: utf-8 -*-
from pptx import Presentation
from pptx.oxml.ns import qn
from pptx.util import Inches

FONT_NAME = "標楷體"
LOGO = "校徽.png"


def set_font(run, name):
    run.font.name = name                     # a:latin
    rPr = run.font._rPr
    for tag in ("a:latin", "a:ea", "a:cs"):
        element = rPr.find(qn(tag))
        if element is None:
            element = rPr.makeelement(qn(tag), {})
            rPr.append(element)
        element.set("typeface", name)


def walk(shapes):
    for shape in shapes:
        if shape.shape_type == 6:            # GROUP
            yield from walk(shape.shapes)
            continue
        if shape.has_text_frame:
            yield shape
        if shape.has_table:
            for row in shape.table.rows:
                for cell in row.cells:
                    yield cell


presentation = Presentation("來源.pptx")
for slide in presentation.slides:
    for holder in walk(slide.shapes):
        for paragraph in holder.text_frame.paragraphs:
            for run in paragraph.runs:
                set_font(run, FONT_NAME)
    slide.shapes.add_picture(                # 右下角校徽
        LOGO,
        presentation.slide_width - Inches(1.4),
        presentation.slide_height - Inches(1.2),
        height=Inches(0.8),
    )

presentation.save("output/來源_已統一字型.pptx")
```

母片（slide master／layout）上的文字不在 `slide.shapes` 裡，
若改完仍有幾頁字型沒變，多半是文字寫在版面配置上，需要另外走
`presentation.slide_masters[*].slide_layouts[*].shapes`。

---

## 驗收

```python
from pptx import Presentation
check = Presentation("output/xxx.pptx")
print(len(check.slides), "頁")
for slide in check.slides:
    print([s.text_frame.text[:20] for s in slide.shapes if s.has_text_frame])
```

頁數對、抽查文字沒有亂碼或空白，再回報完成。
