# teacher-file-toolkit（專案藍圖）

> 本檔為跨 Agent 通用的專案藍圖（AGENTS.md 開放標準）。任何 Agent 的每個 session 都應先讀本檔＋`handoff.md`。

## 專案簡介

提供老師在本機處理 Word、Excel、PowerPoint、PDF、圖片、圖表、QR Code 與 Markdown 教材的工具清單、安裝腳本及驗證方式。目前核心清單 13 項，全部固定版本並通過驗證（`CORE_OK: 13/13`）。本專案不使用 Firebase，也沒有部署目標。

## 關鍵時程

<!-- 目前無固定時程 -->

## 目標與路線圖

- [x] 階段一：核心工具清單、安裝腳本 `install_windows.ps1` 與煙霧測試 `verify_core.py` 成形
- [x] 階段二：納入 `docx2pdf`、`ocrmypdf`、`pypdfium2`，核心清單由 10 項擴充為 13 項
- [x] 階段三：安裝腳本加上 Word 檢查、自動裝 Tesseract＋繁中模型（固定版本 SHA-256）
- [x] 階段四：`verify_core.py` 補上 Word 轉 PDF 與圖片型 PDF OCR 實測，`CORE_OK: 13/13` 通過
- [ ] 階段五：以實際教材測試 Word 批次轉 PDF／JPG，以及繁中掃描 PDF OCR
- [ ] 階段六：只有需要特定 PDF/A 流程時才另外評估 Ghostscript

## 資料夾結構

```
teacher-file-toolkit/
├─ README.md                              # 專案用途與初學者使用方式
├─ AGENT_SETUP_教學檔案處理工具包.md        # 交給 AI Agent 的安裝與安全指引
├─ install_windows.ps1                    # Windows 核心工具安裝腳本
├─ requirements-core.txt                  # 核心 Python 相依套件（固定版本）
├─ verify_core.py                         # 核心套件匯入與檔案處理煙霧測試
├─ 教學檔案處理_工具列表.md                 # 可讀的工具清單來源
├─ 教學檔案處理_工具列表.pdf                # 由 make_pdf.py 產生
├─ make_pdf.py                            # 重新產生工具列表 PDF
├─ Python範例.md
├─ agents.md                              # 本檔：專案藍圖
├─ handoff.md                             # 交接檔（每次收工必更新）
├─ .venv/  .agents/  .gitignore
```

## 同步層級（本專案初始化至第 3 層級）

| 層級 | 平台 | 位置 | 讀取時機 |
|------|------|------|---------|
| L1 | 本地（GDrive） | `agents.md`＋`handoff.md` | 每個 session |
| L2 | GitHub | https://github.com/changyiwu/teacher-file-toolkit （公開，預設分支 `main`） | 指定時 |
| L3 | Obsidian | `teacher-file-toolkit/專案工作流程.md` | 有需要時 |

## 工作約定

- 任何 Agent、任何電腦：**開工先讀 `handoff.md`，收工必更新 `handoff.md`**
- 修改共用檔案前先讀最新內容，避免覆蓋其他 Agent 的變更
- 所有回應與文件使用繁體中文
- 推送前先抓取並確認 `origin/main`、提交範圍及工作區狀態；**禁止 force push**
- 保留既有 Git 歷史與 `main` 分支
- 本專案位於雲端同步資料夾，Git 本機設定應維持 `windows.appendAtomically=false`
- 更新 Obsidian 專案筆記時，不要修改 `02-知識庫/log.md`
- 修改工具清單後，如需同步 PDF，使用 `make_pdf.py` 重新產生並一併驗證

## 安全邊界

- 保留使用者既有修改；不要覆蓋原始教材或輸入檔，處理結果使用新檔名輸出
- 不提交 `.env`、憑證、權杖、密碼、`.codex/` 或 `.claude/`
- 學生資料只使用班級代碼與座號，不儲存真實姓名；預設在本機處理
- 初始化工作區不代表授權部署、變更公開狀態、啟用 GitHub Pages、commit 或 push

## 已知環境陷阱

- `chi_tra.traineddata` 不能寫入 `Program Files`，改放 `%LOCALAPPDATA%\Tesseract-OCR\tessdata`（並複製 `configs`／`tessconfigs`）
- `docx2pdf` 需桌面版 Word，且不支援 `python -m docx2pdf`

## 最近進度

- 2026-07-24：專案藍圖改用標準範本格式（補上路線圖 checklist、資料夾結構與同步層級表）；L3 路徑由不存在的「專案駕駛艙.md」更正為 `teacher-file-toolkit/專案工作流程.md`；L2 由「目前沒有設定 Git 遠端」更正為已連接 `changyiwu/teacher-file-toolkit`。
