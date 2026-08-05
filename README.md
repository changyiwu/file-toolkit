# file-toolkit｜老師的教學檔案處理工具包

> 三師爸 Sense Bar ・ [youtube.com/@sensebar](https://www.youtube.com/@sensebar)

`file-toolkit` 是一套給教學現場老師使用的檔案處理工具包，涵蓋 Word、Excel、PowerPoint、PDF、圖片、圖表、QR Code 與教材轉 Markdown。

## 📦 這個資料夾有什麼

| 檔案 | 說明 |
|------|------|
| [`教學檔案處理_工具列表.md`](教學檔案處理_工具列表.md) | 工具地圖：痛點／套件／一句話，加上安裝與選裝說明 |
| [`AGENT_SETUP_教學檔案處理工具包.md`](AGENT_SETUP_教學檔案處理工具包.md) | 給 AI Agent 讀的安全安裝指南 |
| [`install_windows.ps1`](install_windows.ps1) | Windows 核心工具自動安裝與驗證腳本 |
| [`requirements-core.txt`](requirements-core.txt) | 已篩選的核心 Python 套件清單 |
| [`verify_core.py`](verify_core.py) | 核心套件匯入與檔案處理煙霧測試 |
| [`skill/`](skill/) | 把上述能力打包成的 Agent 技能（`SKILL.md`＋環境腳本＋五份 recipe） |

## 🚀 安裝核心工具

把 [`AGENT_SETUP_教學檔案處理工具包.md`](AGENT_SETUP_教學檔案處理工具包.md) 交給你的 AI Agent，然後說：

> 「讀這份檔案，只安裝裡面的核心工具，選用工具先不要裝。」

Agent 會執行同一支 PowerShell 腳本，以 Python 3.12 建立共用環境 `%LOCALAPPDATA%\file-toolkit\.venv`（與技能同一份，不建在這個 repo 裡）、安裝 13 項核心工具並驗證。核心流程會自動安裝 Tesseract OCR、英文／方向／繁中模型，並驗證 `docx2pdf`；電腦必須已安裝有授權的 Microsoft Word。影音與進階 Office 自動化工具不會自動安裝。

也可以在 Windows PowerShell 直接執行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\install_windows.ps1"
```

> Claude Code、Codex App、Antigravity、OpenCode 在 Windows 原生模式都可使用。若 OpenCode 跑在 WSL，需在 WSL 另建 Linux Python 環境，不能共用 Windows 的 venv。

## 🤖 當成 Agent 技能使用

[`skill/`](skill/) 把這些能力包成一個可安裝的技能（安裝名 `file-toolkit`）。安裝後，直接對 Agent 說
「把這些 PDF 合併」「用這份名單套印獎狀」「這份掃描 PDF 做 OCR」，它會自己備好環境、挑對寫法並輸出到 `output/`。

- 技能會自動尋找可用環境：`FILE_TOOLKIT_PYTHON` → 專案 `.venv` → 共用環境 `%LOCALAPPDATA%\file-toolkit\.venv`（都沒有就用 `uv` 建立）
- 五份 recipe（Word／Excel／PPT／PDF／其他）內的程式碼都經過實測
- 一律輸出新檔，不覆蓋老師的原始教材

## 🧰 工具清單速覽

工具涵蓋套印獎狀、出考卷、成績分析、教材轉簡報、PDF 合併與浮水印、掃描講義 OCR 等常見教學工作。完整內容請參考上方工具清單。

---

> 歡迎自由下載、分享、改作。製作：三師爸 Sense Bar
