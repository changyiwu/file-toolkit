# PDF 處理 recipe

套件：`pypdf`（合併拆分）、`PyMuPDF`（`import fitz`，抽文字與轉圖）、`reportlab`（生成頁面）、`ocrmypdf`＋Tesseract（OCR）

---

## D1. 合併／拆分／抽頁／重排

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from pypdf import PdfReader, PdfWriter

Path("output").mkdir(exist_ok=True)

# 合併（依檔名排序，數字檔名要注意 10 會排在 2 前面）
writer = PdfWriter()
for pdf_path in sorted(Path("考古題").glob("*.pdf"), key=lambda p: p.stem):
    writer.append(str(pdf_path))
with open("output/合併.pdf", "wb") as file:
    writer.write(file)

# 抽出第 5～8 頁（人看到的頁碼；程式從 0 開始）
reader = PdfReader("合併.pdf")
part = PdfWriter()
for page_number in range(5, 9):
    part.add_page(reader.pages[page_number - 1])
with open("output/第5-8頁.pdf", "wb") as file:
    part.write(file)

# 每頁拆成一個檔
for index, page in enumerate(reader.pages, start=1):
    single = PdfWriter()
    single.add_page(page)
    with open(f"output/p{index:03d}.pdf", "wb") as file:
        single.write(file)
```

**驗收**：`len(PdfReader("output/合併.pdf").pages)` 要等於各來源頁數總和。

有密碼的 PDF：`reader.decrypt(password)`；密碼要跟使用者拿，不要嘗試破解。

---

## D2. 加浮水印（班級／防外流）

用 `reportlab` 依「每一頁自己的尺寸」畫一張透明浮水印，再疊上去。
頁面尺寸不一致時共用同一張浮水印會歪掉，所以用快取依尺寸各做一張。

```python
# -*- coding: utf-8 -*-
import io
from pathlib import Path
from pypdf import PdfReader, PdfWriter
from reportlab.lib import colors
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas

TEXT = "302 班 期中複習"
FONT_PATH = Path(r"C:\Windows\Fonts\msjh.ttc")      # 微軟正黑體，中文必備
pdfmetrics.registerFont(TTFont("ZhFont", str(FONT_PATH), subfontIndex=0))


def make_watermark(width, height):
    buffer = io.BytesIO()
    pdf_canvas = canvas.Canvas(buffer, pagesize=(width, height))
    pdf_canvas.setFont("ZhFont", 46)
    pdf_canvas.setFillColor(colors.grey, alpha=0.18)
    pdf_canvas.saveState()
    pdf_canvas.translate(width / 2, height / 2)
    pdf_canvas.rotate(45)
    pdf_canvas.drawCentredString(0, 0, TEXT)
    pdf_canvas.restoreState()
    pdf_canvas.save()
    buffer.seek(0)
    return PdfReader(buffer).pages[0]


reader = PdfReader("講義.pdf")
writer = PdfWriter()
cache = {}
for page in reader.pages:
    size = (round(float(page.mediabox.width), 1), round(float(page.mediabox.height), 1))
    if size not in cache:
        cache[size] = make_watermark(*size)
    page.merge_page(cache[size])                     # 浮水印疊在原內容之上
    writer.add_page(page)

Path("output").mkdir(exist_ok=True)
with open("output/講義_浮水印.pdf", "wb") as file:
    writer.write(file)
```

浮水印是視覺標示，**擋不住複製文字**，不要跟使用者說這樣就防得住外流。

---

## D3. 掃描 PDF OCR → 可搜尋、可複製

前置：先跑一次本技能的 `scripts\ensure_ocr.ps1`（安裝 Tesseract 與 `chi_tra` 繁中模型）。

```python
# -*- coding: utf-8 -*-
from pathlib import Path
import fitz
import ocrmypdf

source = Path("掃描講義.pdf")
target = Path("output/掃描講義_OCR.pdf")
target.parent.mkdir(exist_ok=True)

ocrmypdf.ocr(
    source,
    target,
    language=["chi_tra", "eng"],     # 繁中講義固定用這組；純英文用 ["eng"]
    output_type="pdf",               # 不要用 pdfa，會需要 Ghostscript
    optimize=0,
    skip_text=True,                  # 已經有文字層的頁面跳過，避免重複疊字
    progress_bar=False,
    deskew=True,                     # 掃歪的紙本先校正
)

with fitz.open(target) as document:
    text = "\n".join(page.get_text() for page in document)
print(f"抽到 {len(text.strip())} 字")
print(text[:200])
```

**陷阱**

- OCR 很慢：A4 每頁約 2～5 秒，整本 100 頁先跟使用者說要等；先只做前 3 頁確認辨識品質再全做
- `output_type="pdfa"` 需要 Ghostscript，核心環境沒裝，會直接失敗
- 找不到 `chi_tra`：模型不能放在 `Program Files`，要在 `%LOCALAPPDATA%\Tesseract-OCR\tessdata`
- 辨識率差通常是掃描 dpi 太低（< 200）或紙張太歪，這是來源問題，要如實告訴使用者

---

## D4. 指定頁轉圖片、去白邊

```python
# -*- coding: utf-8 -*-
import io
from pathlib import Path
import fitz
from PIL import Image, ImageChops

PAGES = [12]              # 人看到的頁碼
DPI = 300                 # 要貼進學習單列印用 300

Path("output").mkdir(exist_ok=True)
with fitz.open("課本.pdf") as document:
    for page_number in PAGES:
        pixmap = document[page_number - 1].get_pixmap(dpi=DPI)
        image = Image.open(io.BytesIO(pixmap.tobytes("png"))).convert("RGB")

        background = Image.new("RGB", image.size, (255, 255, 255))
        bbox = ImageChops.difference(image, background).getbbox()   # 去白邊
        if bbox:
            image = image.crop(bbox)

        image.save(f"output/課本_p{page_number}.png")
```

- 只要頁面上的某一張圖（不是整頁）：`document[i].get_images()` ＋ `document.extract_image(xref)`
- 抽文字：`page.get_text()`；抽不到就是圖片型 PDF，要先做 D3 的 OCR
- 轉 JPG 用 `image.save(..., quality=90)`；有透明背景要先 `convert("RGB")`
