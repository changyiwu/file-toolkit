[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$env:PYTHONUTF8 = '1'

$RepoRoot = Split-Path -Parent $PSCommandPath
# Shared with skill/scripts/ensure_env.ps1 so both install into the same environment.
# Never place the venv inside the repo: this repo lives in a cloud-synced folder, and a
# venv hardcodes the absolute path of its base Python, so it breaks on another machine.
$VenvPath = Join-Path $env:LOCALAPPDATA 'file-toolkit\.venv'
$RequirementsPath = Join-Path $RepoRoot 'requirements-core.txt'
$VerifyPath = Join-Path $RepoRoot 'verify_core.py'
$PythonPath = Join-Path $VenvPath 'Scripts\python.exe'

function Test-PythonRuns {
    param([string]$PythonPath)

    if (-not $PythonPath -or -not (Test-Path -LiteralPath $PythonPath)) {
        return $false
    }

    try {
        & $PythonPath -c 'pass' 2>$null | Out-Null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        # Smart App Control blocks the launcher outright, so PowerShell throws instead of
        # returning an exit code. Treat that the same as "this interpreter cannot run".
        return $false
    }
}

function Get-VenvBasePython {
    param([string]$VenvPath)

    # 'home' is the base Python folder; 'executable' is the interpreter itself. uv writes only
    # 'home', and the 'executable' path it would write can point at a version-pinned folder name
    # that no longer exists, so try 'home' first and require both existence and a working run.
    $ConfigPath = Join-Path $VenvPath 'pyvenv.cfg'
    if (-not (Test-Path -LiteralPath $ConfigPath)) {
        return $null
    }

    $HomeCandidates = @()
    $ExecutableCandidates = @()
    foreach ($line in (Get-Content -LiteralPath $ConfigPath)) {
        if ($line -match '^\s*home\s*=\s*(.+?)\s*$') {
            $HomeCandidates += (Join-Path $Matches[1] 'python.exe')
        }
        elseif ($line -match '^\s*executable\s*=\s*(.+?)\s*$') {
            $ExecutableCandidates += $Matches[1]
        }
    }

    foreach ($candidate in ($HomeCandidates + $ExecutableCandidates)) {
        if (Test-PythonRuns -PythonPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Repair-VenvLauncher {
    param([string]$VenvPath, [string]$PythonPath)

    # Smart App Control blocks executables that have no established reputation, and the small
    # launcher uv writes into Scripts\ is one of them: the packages are fine, only the entry
    # point is unusable. Rebuilding with the base Python's own venv module drops a signed
    # python.exe in its place and leaves Lib\site-packages untouched, so nothing is reinstalled.
    $BasePython = Get-VenvBasePython -VenvPath $VenvPath
    if (-not $BasePython) {
        throw "The interpreter at $PythonPath cannot run, most likely blocked by Smart App Control, and no working base Python was found in $VenvPath\pyvenv.cfg. Delete $VenvPath and run this script again."
    }

    Write-Host 'The environment launcher cannot run (Smart App Control). Rebuilding it with the base Python...'
    & $BasePython -m venv $VenvPath
    if ($LASTEXITCODE -ne 0 -or -not (Test-PythonRuns -PythonPath $PythonPath)) {
        throw "Failed to rebuild the launcher at $PythonPath. Delete $VenvPath and run this script again."
    }
    Write-Host 'Launcher rebuilt; the installed packages were kept.'
}

function Find-Uv {
    $command = Get-Command 'uv' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path $env:USERPROFILE '.local\bin\uv.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links\uv.exe')
    )

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Find-WinGet {
    $command = Get-Command 'winget' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidate = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path -LiteralPath $candidate) {
        return $candidate
    }

    return $null
}

function Find-Tesseract {
    $command = Get-Command 'tesseract' -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    $candidates = @(
        (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'Tesseract-OCR\tesseract.exe'),
        (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Tesseract-OCR\tesseract.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Find-Word {
    $registryPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WINWORD.EXE',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WINWORD.EXE'
    )
    foreach ($registryPath in $registryPaths) {
        if (Test-Path -LiteralPath $registryPath) {
            $candidate = (Get-Item -LiteralPath $registryPath).GetValue('')
            if ($candidate -and (Test-Path -LiteralPath $candidate)) {
                return $candidate
            }
        }
    }

    $candidates = @(
        (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'Microsoft Office\Root\Office16\WINWORD.EXE'),
        (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Microsoft Office\Root\Office16\WINWORD.EXE')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

if (-not (Test-Path -LiteralPath $RequirementsPath)) {
    throw "Missing requirements file: $RequirementsPath"
}

Write-Host '[1/6] Checking uv...'
$UvPath = Find-Uv
if (-not $UvPath) {
    $WinGetPath = Find-WinGet
    if (-not $WinGetPath) {
        throw 'uv and WinGet were not found. Install uv from https://docs.astral.sh/uv/ and run this script again.'
    }

    Write-Host 'Installing official astral-sh.uv with WinGet...'
    & $WinGetPath install --exact --id astral-sh.uv --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "uv installation failed. WinGet exit code: $LASTEXITCODE"
    }

    $UvPath = Find-Uv
    if (-not $UvPath) {
        throw 'uv was installed, but this terminal cannot see the new PATH. Restart the Agent and run this script again.'
    }
}

Write-Host "uv: $UvPath"
Write-Host "[2/6] Preparing the shared Python environment at $VenvPath ..."
if (Test-Path -LiteralPath $PythonPath) {
    # Repair before the version check: a launcher blocked by Smart App Control would otherwise
    # abort the script with an unreadable OS error on an environment that is perfectly healthy.
    if (-not (Test-PythonRuns -PythonPath $PythonPath)) {
        Repair-VenvLauncher -VenvPath $VenvPath -PythonPath $PythonPath
    }

    # Reuse anything 3.12 or newer. This environment is shared with the skill, so an exact
    # 3.12 requirement would reject a working newer one and tell the user to delete it.
    $ExistingVersion = & $PythonPath -c "import platform; print(platform.python_version())"
    $ParsedVersion = $null
    if ($LASTEXITCODE -ne 0 -or -not [version]::TryParse($ExistingVersion, [ref]$ParsedVersion) -or $ParsedVersion -lt [version]'3.12') {
        throw "The shared environment at $VenvPath uses Python $ExistingVersion, which is older than 3.12. It was not removed. Delete that folder and run this script again; the skill will rebuild it on next use."
    }
    Write-Host "Reusing the existing shared environment (Python $ExistingVersion)."
}
else {
    & $UvPath venv --python 3.12 $VenvPath --quiet
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $PythonPath)) {
        throw "Failed to create the shared environment at $VenvPath."
    }
    if (-not (Test-PythonRuns -PythonPath $PythonPath)) {
        Repair-VenvLauncher -VenvPath $VenvPath -PythonPath $PythonPath
    }
}

Write-Host '[3/6] Installing 13 core packages (media tools and advanced Office automation are excluded)...'
& $UvPath pip install --python $PythonPath --requirements $RequirementsPath --quiet --quiet --no-progress
if ($LASTEXITCODE -ne 0) {
    throw 'Core package installation failed. Keep the original error above; do not install every optional package as a workaround.'
}

Write-Host '[4/6] Checking Microsoft Word and Tesseract OCR...'
$WordPath = Find-Word
if (-not $WordPath) {
    throw 'Microsoft Word was not found. It is required by the core docx2pdf workflow and cannot be installed automatically because it requires an Office license.'
}
Write-Host "Microsoft Word: $WordPath"

$TesseractPath = Find-Tesseract
if (-not $TesseractPath) {
    $WinGetPath = Find-WinGet
    if (-not $WinGetPath) {
        throw 'Tesseract OCR and WinGet were not found. Install UB-Mannheim.TesseractOCR and run this script again.'
    }

    Write-Host 'Installing Tesseract OCR with WinGet...'
    & $WinGetPath install --exact --id UB-Mannheim.TesseractOCR --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Tesseract OCR installation failed. WinGet exit code: $LASTEXITCODE"
    }
    $TesseractPath = Find-Tesseract
    if (-not $TesseractPath) {
        throw 'Tesseract OCR was installed, but its executable was not found. Restart the Agent and run this script again.'
    }
}
Write-Host "Tesseract OCR: $TesseractPath"

Write-Host '[5/6] Configuring English, orientation, and Traditional Chinese OCR data...'
$SourceTessDataPath = Join-Path (Split-Path -Parent $TesseractPath) 'tessdata'
$TessDataPath = Join-Path $env:LOCALAPPDATA 'Tesseract-OCR\tessdata'
New-Item -ItemType Directory -Path $TessDataPath -Force | Out-Null

foreach ($fileName in @('eng.traineddata', 'osd.traineddata', 'pdf.ttf')) {
    $sourceFile = Join-Path $SourceTessDataPath $fileName
    if (-not (Test-Path -LiteralPath $sourceFile)) {
        throw "Missing Tesseract data file: $sourceFile"
    }
    Copy-Item -LiteralPath $sourceFile -Destination $TessDataPath -Force
}

foreach ($folderName in @('configs', 'tessconfigs')) {
    $sourceFolder = Join-Path $SourceTessDataPath $folderName
    $targetFolder = Join-Path $TessDataPath $folderName
    if (-not (Test-Path -LiteralPath $sourceFolder)) {
        throw "Missing Tesseract configuration folder: $sourceFolder"
    }
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    Get-ChildItem -LiteralPath $sourceFolder -File | Copy-Item -Destination $targetFolder -Force
}

$ChiTraPath = Join-Path $TessDataPath 'chi_tra.traineddata'
$ChiTraHash = '529C5B5797D64B126065CD55F2BB4C7FD7B15790798091B1FF259941A829330B'
$ChiTraUrl = 'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/87416418657359cb625c412a48b6e1d6d41c29bd/chi_tra.traineddata'
$DownloadChiTra = -not (Test-Path -LiteralPath $ChiTraPath)
if (-not $DownloadChiTra) {
    $DownloadChiTra = (Get-FileHash -Algorithm SHA256 -LiteralPath $ChiTraPath).Hash -ne $ChiTraHash
}
if ($DownloadChiTra) {
    $TemporaryChiTraPath = "$ChiTraPath.download"
    try {
        Invoke-WebRequest -Uri $ChiTraUrl -OutFile $TemporaryChiTraPath
        $DownloadedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $TemporaryChiTraPath).Hash
        if ($DownloadedHash -ne $ChiTraHash) {
            throw "Traditional Chinese OCR data hash mismatch: $DownloadedHash"
        }
        Move-Item -LiteralPath $TemporaryChiTraPath -Destination $ChiTraPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $TemporaryChiTraPath) {
            Remove-Item -LiteralPath $TemporaryChiTraPath -Force
        }
    }
}

$env:TESSDATA_PREFIX = $TessDataPath
[Environment]::SetEnvironmentVariable('TESSDATA_PREFIX', $TessDataPath, 'User')
Write-Host "Tesseract data: $TessDataPath"

Write-Host '[6/6] Verifying core packages and file workflows...'
& $PythonPath $VerifyPath
if ($LASTEXITCODE -ne 0) {
    throw 'Core package verification failed.'
}

Write-Host ''
Write-Host 'Installation completed. Use this Python interpreter:'
Write-Host $PythonPath
