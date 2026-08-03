[CmdletBinding()]
param()

# Find or create a Python environment with the 13 core packages.
# The last line printed is the interpreter path.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$env:PYTHONUTF8 = '1'

$ScriptRoot = Split-Path -Parent $PSCommandPath
$RequirementsPath = Join-Path $ScriptRoot 'requirements-core.txt'
$SharedVenv = Join-Path $env:LOCALAPPDATA 'file-toolkit\.venv'
$SharedPython = Join-Path $SharedVenv 'Scripts\python.exe'
# PyMuPDF (fitz) is installed but deliberately not required here: Windows Smart App Control
# blocks its native _mupdf.pyd. The recipes use pypdfium2 for rendering and text extraction.
$ImportCheck = 'import docx, openpyxl, pptx, pypdf, reportlab, PIL, matplotlib, qrcode, markitdown, docx2pdf, ocrmypdf, pypdfium2'

if (-not (Test-Path -LiteralPath $RequirementsPath)) {
    throw "Missing requirements file: $RequirementsPath"
}

function Test-CoreEnv {
    param([string]$PythonPath)

    if (-not $PythonPath -or -not (Test-Path -LiteralPath $PythonPath)) {
        return $false
    }
    & $PythonPath -c $ImportCheck 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
}

function Find-Uv {
    $command = Get-Command 'uv' -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path $env:USERPROFILE '.local\bin\uv.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\uv.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}

# Step 1: reuse an existing environment if one already has the core packages.
$Candidates = @(
    $env:FILE_TOOLKIT_PYTHON,
    (Join-Path (Get-Location).Path '.venv\Scripts\python.exe'),
    $SharedPython
)

foreach ($candidate in $Candidates) {
    if (Test-CoreEnv -PythonPath $candidate) {
        Write-Host 'Reusing existing core environment.'
        Write-Output (Resolve-Path -LiteralPath $candidate).Path
        exit 0
    }
}

# Step 2: no usable environment, so build the shared one.
Write-Host 'No usable core environment found. Creating the shared one...'
$UvPath = Find-Uv
if (-not $UvPath) {
    $WinGet = Get-Command 'winget' -ErrorAction SilentlyContinue
    if (-not $WinGet) {
        throw 'uv and WinGet were not found. Install uv from https://docs.astral.sh/uv/ and run this script again.'
    }
    Write-Host 'Installing astral-sh.uv with WinGet...'
    & $WinGet.Source install --exact --id astral-sh.uv --silent --accept-package-agreements --accept-source-agreements
    $UvPath = Find-Uv
    if (-not $UvPath) {
        throw 'uv was installed, but this terminal cannot see the new PATH. Restart the Agent and run this script again.'
    }
}

if (-not (Test-Path -LiteralPath $SharedPython)) {
    & $UvPath venv --python 3.12 $SharedVenv --quiet
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $SharedPython)) {
        throw "Failed to create the shared environment at $SharedVenv."
    }
}

Write-Host 'Installing 13 core packages (media tools and advanced Office automation are excluded)...'
& $UvPath pip install --python $SharedPython --requirements $RequirementsPath --quiet --no-progress
if ($LASTEXITCODE -ne 0) {
    throw 'Core package installation failed. Keep the original error above; do not install every optional package as a workaround.'
}

if (-not (Test-CoreEnv -PythonPath $SharedPython)) {
    throw 'Core packages were installed, but the import check still fails.'
}

Write-Host 'Shared core environment is ready.'
Write-Output (Resolve-Path -LiteralPath $SharedPython).Path
