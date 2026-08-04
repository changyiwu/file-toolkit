# file-toolkit（專案藍圖）

> 本檔為跨 Agent 通用的專案藍圖（AGENTS.md 開放標準）。任何 Agent 的每個 session 都應先讀本檔＋`handoff.md`。

## 專案簡介

提供老師在本機處理 Word、Excel、PowerPoint、PDF、圖片、圖表、QR Code 與 Markdown 教材的工具清單、安裝腳本及驗證方式。核心清單 13 項全部固定版本，其中 **12 項為必要**、`PyMuPDF` 為選用（開啟 Smart App Control 的 Windows 會封鎖它的原生 DLL），驗證通過為 `CORE_OK: 12/12`。本專案不使用 Firebase，也沒有部署目標。

## 關鍵時程

<!-- 目前無固定時程 -->

## 目標與路線圖

- [x] 階段一：核心工具清單、安裝腳本 `install_windows.ps1` 與煙霧測試 `verify_core.py` 成形
- [x] 階段二：納入 `docx2pdf`、`ocrmypdf`、`pypdfium2`，核心清單由 10 項擴充為 13 項
- [x] 階段三：安裝腳本加上 Word 檢查、自動裝 Tesseract＋繁中模型（固定版本 SHA-256）
- [x] 階段四：`verify_core.py` 補上 Word 轉 PDF 與圖片型 PDF OCR 實測
- [x] 階段五：把檔案處理能力包裝成 `skill/`（SKILL.md＋環境腳本＋五份 recipe），16 段 recipe 程式碼實測通過
- [x] 階段六：PDF 抽文字與轉圖改用 `pypdfium2`，讓技能在開啟 Smart App Control 的電腦也能完整運作（`CORE_OK: 12/12`）
- [x] 階段七：把 `Python範例.md`、`教學檔案處理_工具列表.md`、`AGENT_SETUP_教學檔案處理工具包.md`（連同 `make_pdf.py` 與工具列表 PDF）裡「PDF 轉圖用 PyMuPDF」的敘述同步改為 `pypdfium2`
- [ ] 階段八：以實際教材測試 Word 批次轉 PDF／JPG，以及繁中掃描 PDF OCR
- [ ] 階段九：只有需要特定 PDF/A 流程時才另外評估 Ghostscript

## 資料夾結構

```
file-toolkit/
├─ README.md                              # 專案用途與初學者使用方式
├─ AGENT_SETUP_教學檔案處理工具包.md        # 交給 AI Agent 的安裝與安全指引
├─ install_windows.ps1                    # Windows 核心工具安裝腳本
├─ requirements-core.txt                  # 核心 Python 相依套件（固定版本）
├─ verify_core.py                         # 核心套件匯入與檔案處理煙霧測試
├─ 教學檔案處理_工具列表.md                 # 可讀的工具清單來源
├─ 教學檔案處理_工具列表.pdf                # 由 make_pdf.py 產生
├─ make_pdf.py                            # 重新產生工具列表 PDF
├─ Python範例.md
├─ skill/                                 # 打包成 Agent 技能的原始檔（安裝名：file-toolkit）
│  ├─ SKILL.md                            # 技能主檔：判斷任務→備環境→讀 recipe→執行驗收
│  ├─ scripts/ensure_env.ps1              # 尋找或建立含 13 核心套件的 Python 環境
│  ├─ scripts/ensure_ocr.ps1              # 安裝設定 Tesseract＋繁中模型（OCR 任務前執行）
│  ├─ scripts/requirements-core.txt       # 技能自帶的核心套件清單（與根目錄同版本）
│  └─ references/                         # word／excel／pptx／pdf／misc 五份實測 recipe
├─ agents.md                              # 本檔：專案藍圖
├─ handoff.md                             # 交接檔（每次收工必更新）
├─ .venv/  .agents/  .gitignore
```

## 同步層級（本專案初始化至第 3 層級）

| 層級 | 平台 | 位置 | 讀取時機 |
|------|------|------|---------|
| L1 | 本地（GDrive） | `agents.md`＋`handoff.md` | 每個 session |
| L2 | GitHub | https://github.com/changyiwu/file-toolkit （公開，預設分支 `main`） | 指定時 |
| L3 | Obsidian | `file-toolkit/專案工作流程.md` | 有需要時 |

## 三個檔案的職責（依「時效性」分家，不是依「詳細程度」）

| 檔案 | 時效 | 寫入方式 | 放什麼 |
|------|------|---------|--------|
| `handoff.md` | **只對下一個 session 有效**，過期即丟 | 每次收工整份重寫 | 做到哪、下一步、**這次**的暫時 workaround |
| `agents.md`（本檔） | **長期有效**，每個 session 都適用 | 只有規則本身變了才改 | 目標、路線圖、常設規則、結構 |
| Obsidian／`git log` | **歷史**：發生過什麼、為什麼 | 只增不刪 | 決策紀錄、踩坑完整版、逐次進度 |

驗收標準：**`handoff.md` 整份刪掉，不應損失任何長期資訊**——會的話代表該升級進本檔卻沒升級。

**本檔不要出現的東西**：❌ `## 最近進度`／逐次工作紀錄、❌ 決策理由與踩坑完整版。2026-08-03 移除了 `## 最近進度`，內容逐條比對後已在 L3 筆記的〈🗓️ 最近更動紀錄〉——**是主動移除，不是遺漏，不要補回來**。踩過的坑只把**結論**收斂成一條祈使句寫進〈工作約定〉，原因留 L3。

## 工作約定

- 任何 Agent、任何電腦：**開工先讀 `handoff.md`，收工必更新 `handoff.md`**
- 修改共用檔案前先讀最新內容，避免覆蓋其他 Agent 的變更
- 所有回應與文件使用繁體中文
- 推送前先抓取並確認 `origin/main`、提交範圍及工作區狀態；**禁止 force push**
- 保留既有 Git 歷史與 `main` 分支
- 本專案位於雲端同步資料夾，Git 本機設定應維持 `windows.appendAtomically=false`
- 更新 Obsidian 專案筆記時，不要修改 `02-知識庫/log.md`
- 修改工具清單後，如需同步 PDF，使用 `make_pdf.py` 重新產生並一併驗證（`make_pdf.py` 的表格是硬寫在程式裡的，不是讀 `.md`，兩邊都要改）
- PDF 抽文字與轉圖一律用 `pypdfium2`，程式碼與說明文件都不要再出現「用 PyMuPDF／`import fitz`」的敘述

## 安全邊界

- 保留使用者既有修改；不要覆蓋原始教材或輸入檔，處理結果使用新檔名輸出
- 不提交 `.env`、憑證、權杖、密碼、`.codex/` 或 `.claude/`
- 學生資料只使用班級代碼與座號，不儲存真實姓名；預設在本機處理
- 初始化工作區不代表授權部署、變更公開狀態、啟用 GitHub Pages、commit 或 push

## 已知環境陷阱

- `chi_tra.traineddata` 不能寫入 `Program Files`，改放 `%LOCALAPPDATA%\Tesseract-OCR\tessdata`（並複製 `configs`／`tessconfigs`）
- `docx2pdf` 需桌面版 Word，且不支援 `python -m docx2pdf`
- `.ps1` 一律只寫 ASCII：`powershell.exe`（5.1）會用 Big5 解讀無 BOM 的 UTF-8，中文註解的結尾會吃掉下一行程式碼
- **Smart App Control（部分 Windows 11 預設開啟，如 NB-YI）**會封鎖未取得信譽的執行檔與原生 DLL：`uv.exe` 完全不能執行（改用系統 Python 的 `venv`＋`pip` 建環境）、PyMuPDF 的 `_mupdf.pyd` 永久載入失敗（`import fitz` → `No module named 'mupdf'`）。判斷指令：`(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy').VerifiedAndReputablePolicyState`，`1` 為開啟。**SAC 一旦關閉就無法再開啟（需重設 Windows），不要建議使用者關掉它**
- `.venv` 綁定建立當下的 base Python 絕對路徑，放在雲端同步資料夾**不能跨電腦共用**；共用環境一律建在 `%LOCALAPPDATA%\file-toolkit\.venv`
- `ocrmypdf` 執行時會探測選用外部程式，印出數行 `[WinError 2] 系統找不到指定的檔案。` 屬正常，不影響結果
- 跑 OCR 前必須有 `TESSDATA_PREFIX`。`ensure_ocr.ps1` 會設在使用者層級，但**同一個 session 已開的 shell 讀不到**——要重開 shell 或當場再設一次
- `pypdfium2` 的 `scale` 以 72 dpi 為 1.0，換算是 `scale = dpi / 72`；抽文字用 `page.get_textpage().get_text_range()`
