# teacher-file-toolkit｜老師的教學檔案處理工具包

> 三師爸 Sense Bar ・ [youtube.com/@sensebar](https://www.youtube.com/@sensebar)

`teacher-file-toolkit` 是一套給教學現場老師使用的檔案處理工具包，涵蓋 Word、Excel、PowerPoint、PDF、圖片、圖表、QR Code 與教材轉 Markdown。

## 📦 這個資料夾有什麼

| 檔案 | 說明 |
|------|------|
| [`教學檔案處理_工具列表.md`](教學檔案處理_工具列表.md) | 老師的 Python 工具清單（痛點／套件／一句話） |
| [`教學檔案處理_工具列表.pdf`](教學檔案處理_工具列表.pdf) | 上面清單的一頁式 PDF，方便列印／下載 |
| [`AGENT_SETUP_教學檔案處理工具包.md`](AGENT_SETUP_教學檔案處理工具包.md) | 給 AI Agent 讀的安全安裝指南 |
| [`install_windows.ps1`](install_windows.ps1) | Windows 核心工具自動安裝與驗證腳本 |
| [`requirements-core.txt`](requirements-core.txt) | 已篩選的核心 Python 套件清單 |
| [`Python範例.md`](Python範例.md) | 完整工具地圖與選用說明 |
| [`make_pdf.py`](make_pdf.py) | 重新產生 PDF 的腳本 |
| [`verify_core.py`](verify_core.py) | 核心套件匯入與檔案處理煙霧測試 |

## 🚀 安裝核心工具

把 [`AGENT_SETUP_教學檔案處理工具包.md`](AGENT_SETUP_教學檔案處理工具包.md) 交給你的 AI Agent，然後說：

> 「讀這份檔案，只安裝裡面的核心工具，選用工具先不要裝。」

Agent 會執行同一支 PowerShell 腳本，以 Python 3.12 建立本資料夾專用的 `.venv`、安裝 10 項核心工具並驗證。OCR、影音、Office COM 等進階工具不會自動安裝，避免初學者卡在系統相依。

也可以在 Windows PowerShell 直接執行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install_windows.ps1"
```

> Claude Code、Codex App、Antigravity、OpenCode 在 Windows 原生模式都可使用。若 OpenCode 跑在 WSL，需在 WSL 另建 Linux Python 環境，不能共用 Windows `.venv`。

## 🧰 工具清單速覽

工具涵蓋套印獎狀、出考卷、成績分析、教材轉簡報、PDF 合併與浮水印、掃描講義 OCR 等常見教學工作。完整內容請參考上方工具清單。

---

> 歡迎自由下載、分享、改作。製作：三師爸 Sense Bar
