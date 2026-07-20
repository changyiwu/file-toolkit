# teacher-file-toolkit 專案規則

## 專案定位

- 專案名稱：`teacher-file-toolkit`
- 專案路徑：`C:\Users\chang\我的雲端硬碟\agents\teacher-file-toolkit`
- 用途：提供老師在本機處理 Word、Excel、PowerPoint、PDF、圖片、圖表、QR Code 與 Markdown 教材的工具清單、安裝腳本及驗證方式。
- 本專案目前不使用 Firebase，也沒有部署目標。

## 工作入口

- `README.md`：專案用途與初學者使用方式。
- `AGENT_SETUP_教學檔案處理工具包.md`：交給 AI Agent 的安裝與安全指引。
- `install_windows.ps1`：Windows 核心工具安裝腳本。
- `requirements-core.txt`：核心 Python 相依套件。
- `verify_core.py`：核心套件匯入與檔案處理煙霧測試。
- `教學檔案處理_工具列表.md`：可讀的工具清單來源。
- `make_pdf.py`：重新產生 `教學檔案處理_工具列表.pdf`。

## Obsidian 連結

- 主要 Vault：`C:\Users\chang\我的雲端硬碟\2ndbrain`
- 專案駕駛艙：`teacher-file-toolkit-專案駕駛艙.md`（位於 Vault 根目錄）
- 開工時先讀取駕駛艙與 `git status`；收工時更新駕駛艙的最後動作、狀態、下一步與踩坑筆記。
- 不要為駕駛艙建立子資料夾，也不要因駕駛艙更新而修改 `知識庫/log.md`。

## Git 與同步規則

- 保留既有 Git 歷史與 `main` 分支。
- 目前沒有設定 Git 遠端；未經使用者明確要求，不建立 GitHub 儲存庫、不設定遠端、不提交、不推送。
- 若日後連接個人 GitHub，預設可寫入的遠端為 `origin`，網址格式為 `https://github.com/changyiwu/<repository>.git`。
- 推送前先抓取並確認 `origin/main`、提交範圍及工作區狀態；禁止 force push。
- 本專案位於雲端同步資料夾，Git 本機設定應維持 `windows.appendAtomically=false`。

## 安全邊界

- 保留使用者既有修改；不要覆蓋原始教材或輸入檔，處理結果使用新檔名輸出。
- 不提交 `.env`、憑證、權杖、密碼、`.codex/` 或 `.claude/`。
- 學生資料只使用班級代碼與座號，不儲存真實姓名；預設在本機處理。
- 修改工具清單後，如需同步 PDF，使用 `make_pdf.py` 重新產生並一併驗證。
- 初始化工作區不代表授權部署、變更公開狀態、啟用 GitHub Pages、commit 或 push。
