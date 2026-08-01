# 其他常用小工具 recipe

套件：`qrcode[pil]`、`markitdown`、`pillow`、`matplotlib`

---

## M1. 連結轉 QR Code

```python
# -*- coding: utf-8 -*-
from pathlib import Path
import qrcode

LINKS = {
    "課堂表單": "https://forms.gle/xxxx",
    "Padlet": "https://padlet.com/xxxx",
}

output_dir = Path("output/qr"); output_dir.mkdir(parents=True, exist_ok=True)
for name, url in LINKS.items():
    qr = qrcode.QRCode(
        version=None,
        error_correction=qrcode.constants.ERROR_CORRECT_M,   # 印在學習單上用 M 即可
        box_size=10,
        border=4,                                            # 邊界不要小於 4，掃不到
    )
    qr.add_data(url)
    qr.make(fit=True)
    qr.make_image(fill_color="black", back_color="white").save(output_dir / f"{name}.png")
```

要在中央放 logo 的話用 `ERROR_CORRECT_H`，且 logo 面積不超過 QR 的 1/5。
產出後提醒使用者實際用手機掃一次再印。

---

## M2. 教材轉 Markdown（餵 AI 前處理）

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from markitdown import MarkItDown

converter = MarkItDown()
output_dir = Path("output/md"); output_dir.mkdir(parents=True, exist_ok=True)

for source in Path("教材").iterdir():
    if source.suffix.lower() not in {".pdf", ".docx", ".pptx", ".xlsx"}:
        continue
    result = converter.convert(str(source))
    text = result.text_content.strip()
    if not text:
        print(f"[空白] {source.name}：可能是掃描檔，需先做 OCR（見 pdf.md D3）")
        continue
    (output_dir / f"{source.stem}.md").write_text(text, encoding="utf-8")
```

`markitdown` 轉出來的是「乾淨文字」，排版、表格框線、圖片位置會流失，
用途是餵 AI 或抽內容，**不要拿來當成教材的保存版本**。

---

## M3. 圖片批次縮放／轉檔／加浮水印文字

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

MAX_SIDE = 1600
SUFFIXES = {".jpg", ".jpeg", ".png", ".webp", ".bmp"}

output_dir = Path("output/images"); output_dir.mkdir(parents=True, exist_ok=True)
for source in sorted(p for p in Path("原圖").iterdir() if p.suffix.lower() in SUFFIXES):
    with Image.open(source) as image:
        image = image.convert("RGB")
        image.thumbnail((MAX_SIDE, MAX_SIDE))        # 等比縮小，不放大
        draw = ImageDraw.Draw(image)
        font = ImageFont.truetype(r"C:\Windows\Fonts\msjh.ttc", 28)
        draw.text((20, image.height - 50), "光武國中", fill=(255, 255, 255), font=font,
                  stroke_width=2, stroke_fill=(0, 0, 0))
        image.save(output_dir / f"{source.stem}.jpg", quality=88)
```

手機拍的照片會有 EXIF 旋轉資訊，若輸出後方向不對：
`from PIL import ImageOps; image = ImageOps.exif_transpose(image)`。

---

## M4. matplotlib 中文設定（所有畫圖任務共用）

```python
import matplotlib
matplotlib.use("Agg")                 # 沒有視窗環境，一定要先設
import matplotlib.pyplot as plt

plt.rcParams["font.sans-serif"] = ["Microsoft JhengHei", "Noto Sans TC", "DFKai-SB"]
plt.rcParams["axes.unicode_minus"] = False    # 負號才不會變成方框
```

圖上出現方框＝字型沒吃到。可用下列指令確認系統有哪些中文字型：

```python
from matplotlib import font_manager
print([f.name for f in font_manager.fontManager.ttflist if "JhengHei" in f.name or "Noto" in f.name])
```

---

## M5. 影音與字幕（選裝，預設不要裝）

`edge-tts`（講稿轉語音）、`yt-dlp`（下載）、`youtube-transcript-api`（抓字幕）都不在核心 13 項。
使用者提出需求時先說明「這需要額外安裝一個套件」，同意後再單獨裝一項。

下載他人影片與字幕涉及著作權，只在使用者自己的內容或明確授權的素材上進行。
