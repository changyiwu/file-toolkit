# Word 處理 recipe

套件：`python-docx`（讀寫）、`docx2pdf`（轉 PDF，需桌面版 Word）、`pypdfium2`（PDF 轉圖）、`openpyxl`（讀名單）

---

## W1. 名單套印（獎狀／通知單／個人成績單）

模板做法：請使用者在 Word 模板裡把要換掉的地方寫成 `{{姓名}}`、`{{班級}}`、`{{分數}}`。

**關鍵陷阱**：Word 會把一段文字拆成多個 run（改過字體、選字時就會拆），
直接 `run.text = ...` 只會改到片段，佔位符常常跨 run 而取代失敗。
一律用下面這個「整段合併後再寫回第一個 run」的寫法。

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from docx import Document
from openpyxl import load_workbook


def replace_placeholders(document, mapping):
    """跨 run 取代 {{欄位}}，保留該段第一個 run 的格式。"""
    def handle(paragraph):
        runs = paragraph.runs
        if not runs:
            return
        original = "".join(run.text for run in runs)
        replaced = original
        for key, value in mapping.items():
            replaced = replaced.replace("{{%s}}" % key, "" if value is None else str(value))
        if replaced == original:
            return
        runs[0].text = replaced
        for run in runs[1:]:
            run.text = ""

    targets = list(document.paragraphs)
    for table in document.tables:
        for row in table.rows:
            for cell in row.cells:
                targets.extend(cell.paragraphs)
    for section in document.sections:          # 頁首頁尾也要換
        targets.extend(section.header.paragraphs)
        targets.extend(section.footer.paragraphs)
    for paragraph in targets:
        handle(paragraph)


template_path = Path(r"獎狀模板.docx")
roster_path = Path(r"名單.xlsx")
output_dir = Path("output"); output_dir.mkdir(exist_ok=True)

sheet = load_workbook(roster_path, data_only=True).active
header = [str(c.value).strip() if c.value is not None else "" for c in sheet[1]]

for row in sheet.iter_rows(min_row=2, values_only=True):
    if not any(row):
        continue
    data = dict(zip(header, row))
    document = Document(template_path)         # 每人都重新開模板，不要重複用同一個物件
    replace_placeholders(document, data)
    name = f'{data.get("班級", "")}_{data.get("座號", "")}_{data.get("姓名", "")}'.strip("_")
    document.save(output_dir / f"{name}.docx")
```

**取代後要轉 PDF**：先全部產出 `.docx`，再用 W3 一次整個資料夾轉檔（比一份一份呼叫快很多）。

**驗收**：檔案數量要等於名單人數；隨機開一份確認沒有殘留 `{{`。

```python
leftovers = [p.name for p in output_dir.glob("*.docx")
             if "{{" in "\n".join(x.text for x in Document(p).paragraphs)]
```

---

## W2. 同一份題目產出「學生卷」與「教師卷」

做法：教師卷是完整版，學生卷把答案段落刪掉。請使用者在答案段落開頭加標記（例如 `【答案】`）。

```python
# -*- coding: utf-8 -*-
from pathlib import Path
from docx import Document

ANSWER_MARKS = ("【答案】", "【詳解】")


def delete_paragraph(paragraph):
    element = paragraph._element
    element.getparent().remove(element)


source = Path("段考題目_教師卷.docx")
student = Document(source)
for paragraph in list(student.paragraphs):
    if paragraph.text.strip().startswith(ANSWER_MARKS):
        delete_paragraph(paragraph)
student.save("output/段考題目_學生卷.docx")
```

答案若是夾在題目同一段（例如括號內），改用 W1 的 `replace_placeholders`，
把 `mapping` 換成正規表示式清除，不要整段刪掉。

---

## W3. Word 批次轉 PDF，再逐頁轉 JPG

```python
# -*- coding: utf-8 -*-
from pathlib import Path
import pypdfium2 as pdfium
from docx2pdf import convert

src_dir = Path("講義")
pdf_dir = Path("output/pdf"); pdf_dir.mkdir(parents=True, exist_ok=True)
jpg_dir = Path("output/jpg"); jpg_dir.mkdir(parents=True, exist_ok=True)

convert(str(src_dir), str(pdf_dir))            # 整個資料夾一次轉，比逐檔呼叫快

for pdf_path in sorted(pdf_dir.glob("*.pdf")):
    document = pdfium.PdfDocument(pdf_path)
    try:
        for index, page in enumerate(document, start=1):
            image = page.render(scale=200 / 72).to_pil()   # 200 dpi 夠印講義；要貼簡報用 150/72
            image.convert("RGB").save(jpg_dir / f"{pdf_path.stem}_p{index:02d}.jpg", quality=90)
    finally:
        document.close()
```

**陷阱**

- `docx2pdf` 需要桌面版 Microsoft Word，**不支援** `python -m docx2pdf`
- 轉檔期間 Word 會被自動操作，請使用者先關閉開著的 Word 檔（有未存檔對話框會卡住）
- 檔名有 `~$` 開頭的是 Word 暫存檔，要排除：`if p.name.startswith("~$"): continue`
- 轉完務必檢查份數：`len(list(pdf_dir.glob("*.pdf"))) == len(docx_files)`

---

## W4. 合併多份 Word

核心包沒有 `docxcompose`。**先問使用者**能不能接受「各自轉 PDF 後合併 PDF」（見 `pdf.md` D1），
可以的話不用裝任何東西；真的要合併成單一 `.docx` 才安裝 `docxcompose`。
