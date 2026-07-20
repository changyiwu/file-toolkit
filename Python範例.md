# Python 能力：教學現場老師的「檔案處理」工具地圖

> 來源：2026.07 依官方文件與乾淨 Python 3.12 環境重新盤點。
> 受眾（TA / Target Audience）：**教學現場的老師**。
> 用途：「執行程式與裝工具」的教學示範素材。
> 主軸：聚焦老師天天在處理的 **Word／Excel／PPT／PDF**，痛點都是「人工做很煩、量一大就爆炸」。
> 圖例：🟢＝核心包自動安裝　🟡＝按需求選裝

---

## 一、套件總覽（依用途分類）

| 類別 | 代表套件 | 能做什麼 |
|------|----------|----------|
| 📄 Word | 🟢 `python-docx`、`docx2pdf`；🟡 `docxcompose` | 生成/讀寫、Word 轉 PDF/JPG；選用合併 Word |
| 📊 Excel | 🟢 `openpyxl`；🟡 `pandas`、`xlsxwriter` | 一般讀寫；選用進階分析/輸出 |
| 📑 PPT | 🟢 `python-pptx` | 生成/改寫 PowerPoint |
| 📕 PDF | 🟢 `PyMuPDF`、`pypdf`、`reportlab`、`ocrmypdf`、`pypdfium2` | 合併/拆分/抽文字/轉圖/浮水印/生成/OCR |
| 🔄 轉檔 | 🟢 `markitdown[pdf,docx,pptx,xlsx]` | 常用文件轉 Markdown |
| 🖼️ 圖像/圖表 | 🟢 `pillow`、`matplotlib`、`qrcode[pil]` | 圖片處理、數據圖、QR Code |
| 🎙️ 語音影音 | 🟡 `edge-tts`、`yt-dlp`、`youtube-transcript-api` | 只在旁白、下載、字幕任務選裝 |

---

## 二、教學檔案處理：老師最有感的專案（核心 demo）

每個都附：痛點 → 用到的套件 → 對 Agent 說的一句話。

### 📄 Word 篇

**W1. 🏆 套印個人化通知單／獎狀／成績單（mail merge）**　🟢
- **痛點**：30 個學生要 30 張獎狀／30 份個別通知單，手動換名字換到天荒地老
- **套件**：`python-docx`（套模板）+ `openpyxl`（讀名單）
- **一句話**：「讀這份班級名單 Excel，套進這個獎狀 Word 模板，每個學生產一份，存成 PDF」

**W2. 📝 出考卷／學習單，題目卷與答案卷分開**　🟢
- **痛點**：出完題還要手動做一份去掉答案的版本
- **套件**：`python-docx`
- **一句話**：「把這些題目做成 Word，產出『學生卷（無答案）』和『教師卷（含詳解）』兩份」

**W3. 📚 Word 批次轉 PDF／JPG**　🟢`docx2pdf`＋`PyMuPDF`
- **痛點**：多份 Word 要逐一另存 PDF，再逐頁轉成圖片
- **套件**：`docx2pdf`（需桌面版 Microsoft Word）+ `PyMuPDF`（PDF 逐頁轉 JPG）
- **一句話**：「把這資料夾的 Word 全部轉成 PDF，再把每頁輸出成 JPG」

### 📊 Excel 篇

**E1. 🧮 成績計算 + 排名 + 及格標示 + 各班統計**　🟢`openpyxl`
- **痛點**：算平均、加權、排名、標紅不及格，每次段考重來一遍
- **套件**：`openpyxl`（讀寫與格式化）
- **一句話**：「讀 grades.xlsx，算總分與排名，不及格標紅，各班平均放最後一列，存成新檔」

**E2. 📈 段考成績分析（各題答對率、平均、落點圖）**　🟢`matplotlib`＋🟡`pandas`
- **痛點**：想看哪一題全班錯最多、班級落點，但不會做統計圖
- **套件**：`pandas`（分析）+ `matplotlib`（畫圖）
- **一句話**：「分析這份答題明細，畫出各題答對率長條圖和全班分數分布圖」

**E3. ✂️ 把總成績單「拆成」各班／各學生個別檔**　🟢`openpyxl`
- **痛點**：一份大表要拆成各班導師各自的檔、或每生一張個人成績單
- **套件**：`openpyxl`
- **一句話**：「把這份全校成績表，依『班級』欄拆成一個班一個 Excel 檔」

**E4. 🪑 自動產生座位表 / 隨機分組**　🟢`openpyxl`
- **痛點**：每次調座位、分組都要手喬
- **套件**：`openpyxl`（+ 內建 random）
- **一句話**：「用這份名單隨機排一張 6×5 的座位表，輸出成 Excel」

### 📑 PPT 篇

**P1. 🪄 教材大綱 → 自動生成整份上課簡報**　🟢
- **痛點**：把講義重點一頁一頁貼進 PPT 很花時間
- **套件**：`python-pptx`
- **一句話**：「把這份教材大綱，每個重點做成一頁投影片，套用這個範本」

**P2. 🖼️ 一堆圖片 → 自動排成圖卡簡報**　🟢`python-pptx`＋`pillow`
- **痛點**：單字卡、生物圖鑑、作品集，要一張張貼進 PPT
- **套件**：`python-pptx` + `pillow`
- **一句話**：「把這資料夾的圖片，每張做成一頁投影片，下方加上檔名當標題」

**P3. 🎨 統一整份簡報的字型／字級／加上校徽**　🟢
- **痛點**：別人給的 PPT 字體亂七八糟，要逐頁改
- **套件**：`python-pptx`
- **一句話**：「把這份 PPT 全部字型改成標楷體、每頁右下角加上這張校徽」

### 📕 PDF 篇

**D1. 📎 考卷合併 / 拆分 / 重新排序**　🟢
- **痛點**：考古題、學生作業散在幾十個 PDF
- **套件**：`pypdf`、`PyMuPDF`
- **一句話**：「把這些 PDF 合併成一份，並把第 5～8 頁單獨抽出來另存」

**D2. 💧 PDF 加浮水印（班級／姓名／防外流）**　🟢
- **痛點**：講義或考卷想加上「僅供 ○ 班使用」防止外流
- **套件**：`pypdf`、`reportlab`
- **一句話**：「幫這份 PDF 每頁加上淡灰色浮水印『302 班 期中複習』」

**D3. 🔍 掃描的紙本講義 OCR → 可搜尋、可複製**　🟢`ocrmypdf`＋`pypdfium2`＋Tesseract
- **痛點**：掃描的考古題是圖片，無法選取文字、無法餵 AI
- **套件**：`ocrmypdf`、`pypdfium2`、Tesseract（英文／方向／繁中模型）
- **一句話**：「把這份掃描 PDF 做 OCR，變成可以複製文字的 PDF」

**D4. 🧩 抽課本某幾頁 / PDF 轉圖貼到學習單**　🟢`PyMuPDF`
- **痛點**：只要課本某張圖、某幾頁貼進學習單
- **套件**：`PyMuPDF`
- **一句話**：「把這份課本 PDF 的第 12 頁轉成圖片，去掉白邊」

---

## 三、其他老師小工具

| 工具 | 一句話 |
|------|--------|
| 🟢 連結轉 QR Code（`qrcode[pil]`） | 「把這 5 個連結各生一張 QR Code，貼到學習單」 |
| 🟡 抓 YouTube 現成字幕（`youtube-transcript-api`） | 「抓這支 YouTube 影片的字幕，整理成逐字稿」 |
| 🟡 講稿轉語音旁白（`edge-tts`） | 「把這份講稿轉成中文語音 mp3」 |
| 🟢 課本轉乾淨文字（`markitdown[pdf,docx,pptx,xlsx]`） | 「把這份 PDF/PPT 轉成 Markdown 餵 AI」 |

---

## 四、核心環境與選用工具

> 不用自己一條條敲——把 [`AGENT_SETUP_教學檔案處理工具包.md`](AGENT_SETUP_教學檔案處理工具包.md)
> 交給你的 Agent，它會安裝核心包、Tesseract 與繁中模型並驗證；不會自動安裝 Ghostscript、影音或進階 Office 工具。

**核心套件（一鍵，安裝到本 repo 的 `.venv`）**

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install_windows.ps1"
```

核心清單：`python-docx`、`openpyxl`、`python-pptx`、`pypdf`、`PyMuPDF`、
`reportlab`、`pillow`、`matplotlib`、`qrcode[pil]`、`markitdown[pdf,docx,pptx,xlsx]`、
`docx2pdf`、`ocrmypdf`、`pypdfium2`。其中 `docx2pdf` 需要電腦已安裝 Microsoft Word。

**按需求選裝，不要一次全裝**

| 套件 | 原因 |
|------|------|
| `docxcompose` | 只有合併多份 Word 才需要；Word 轉 PDF 已由核心 `docx2pdf` 處理。 |
| `xlsxwriter`、`pandas` | 進階 Excel 輸出與資料分析；一般工作可先用 `openpyxl`。 |
| `pdfplumber`、`pdf2image` | 與核心 PDF 工具重疊；`pdf2image` 還需 Poppler。 |
| `edge-tts`、`yt-dlp`、`youtube-transcript-api` | 影音或字幕任務才需要。 |

**系統工具（非 pip，需個別安裝）**

| 工具 | 給誰用 | Windows 安裝 |
|------|--------|--------------|
| Tesseract（含繁中包 `chi_tra`） | 核心 `ocrmypdf` 掃描 OCR | 核心腳本自動安裝與設定 |
| Ghostscript | OCRmyPDF 部分 PDF/A／Windows 流程 | 官方 Windows 安裝可能需手動與管理員權限 |
| Poppler | `pdf2image` PDF 轉圖 | `winget install oschwartz10612.Poppler` |
| ffmpeg | `yt-dlp` 下載合併 | `winget install Gyan.FFmpeg` |
| Microsoft Word | `docx2pdf` Word→PDF | 需安裝 Office（無則改用 LibreOffice） |

> ⚠️ Tesseract 是核心系統元件，Microsoft Word 是 `docx2pdf` 的核心前置。Ghostscript、Poppler、ffmpeg 仍按需求選裝；
> 裝完會修改 PATH 的系統工具後，需重開終端機或重啟 Agent。

---

## 五、教學鋪陳建議

- **三大頭牌 demo（最有感、最好炒氣氛）**：
  1. **W1 套印獎狀／通知單**——「30 張獎狀一秒生」最震撼，幾乎每位老師都做過。
  2. **E1+E2 成績全套**——計算、排名、拆班、畫分析圖，命中行政庶務痛點。
  3. **P1 教材變整份 PPT**——備課時間直接砍半。
- **節奏**：每個格式（Word→Excel→PPT→PDF）各挑 1 個現場 demo，剛好對應「能力② 執行程式」一段。
- **誠實提醒**：示範前若有套件沒裝，讓觀眾看到「Agent 自己會把缺的套件裝起來」——正好呼應本集「執行程式與裝工具」的主題。

---

## 參考來源（2026.06 上網查找）
- Word Mail Merge with Python：https://learndataanalysis.org/automate-microsoft-word-mail-merge-with-python/
- 大量證書/獎狀套印（教師實例）：https://frankbuck.org/certificate-creation/
- 從 Excel/Google Sheets 生成證書：https://certifier.io/blog/how-to-create-certificates-from-google-sheets-and-excel
