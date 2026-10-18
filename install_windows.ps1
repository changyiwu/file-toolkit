[CmdletBinding()]
param()

# Windows entry point for the core toolkit. It does not reimplement any setup logic: it chains the
# skill's two cross-platform scripts (ensure_env.ps1, ensure_ocr.ps1), adds the Microsoft Word check
# that docx2pdf needs, and runs verify_core.py. Fix setup bugs in those scripts, not here.
# Requires PowerShell 7 (pwsh), same as the scripts it calls.

# Before Set-StrictMode: under strict mode 5.1 fails on the undefined $IsWindows with an unreadable
# "variable has not been set" error instead of this message.
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 (pwsh) is required; 5.1 cannot parse the skill scripts. Install it with: winget install Microsoft.PowerShell, then run: pwsh -NoProfile -ExecutionPolicy Bypass -File ./install_windows.ps1'
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding
$env:PYTHONUTF8 = '1'

if (-not $IsWindows) {
    throw 'install_windows.ps1 is Windows only. On macOS run skill/scripts/ensure_env.ps1 and skill/scripts/ensure_ocr.ps1, then verify_core.py.'
}

$RepoRoot = Split-Path -Parent $PSCommandPath
$ScriptsDir = Join-Path $RepoRoot 'skill' 'scripts'
$EnsureEnvPath = Join-Path $ScriptsDir 'ensure_env.ps1'
$EnsureOcrPath = Join-Path $ScriptsDir 'ensure_ocr.ps1'
$RequirementsPath = Join-Path $ScriptsDir 'requirements-core.txt'
$RootRequirementsPath = Join-Path $RepoRoot 'requirements-core.txt'
$VerifyPath = Join-Path $RepoRoot 'verify_core.py'

foreach ($path in @($EnsureEnvPath, $EnsureOcrPath, $RequirementsPath, $RootRequirementsPath, $VerifyPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing file: $path"
    }
}

# The root copy is what readers of the repo see; the skill installs from its own copy so it still
# works once copied out of the repo. A silent drift between the two would install the wrong list.
if ((Get-FileHash -LiteralPath $RootRequirementsPath).Hash -ne (Get-FileHash -LiteralPath $RequirementsPath).Hash) {
    throw "requirements-core.txt differs from skill/scripts/requirements-core.txt. Make the two files identical and run this script again."
}

function Find-Uv {
    $command = Get-Command 'uv' -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path $env:USERPROFILE '.local' 'bin' 'uv.exe'),
        (Join-Path $env:LOCALAPPDATA 'Microsoft' 'WinGet' 'Links' 'uv.exe')
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
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

Write-Host '[1/5] Preparing the shared Python environment (skill/scripts/ensure_env.ps1)...'
# ensure_env.ps1 prints progress with Write-Host and the interpreter path as its last output line.
$EnvOutput = @(& $EnsureEnvPath)
$PythonPath = if ($EnvOutput.Count -gt 0) { [string]$EnvOutput[-1] } else { $null }
if (-not $PythonPath -or -not (Test-Path -LiteralPath $PythonPath)) {
    throw 'ensure_env.ps1 did not report a usable Python interpreter. Keep the error above.'
}
Write-Host "Python: $PythonPath"

Write-Host '[2/5] Syncing the 12 core packages with the pinned list...'
# ensure_env.ps1 reuses any environment whose imports pass, even with older pins. This installer is
# also the "repair" entry point, so bring the versions back in line with the list.
$UvPath = Find-Uv
if ($UvPath) {
    & $UvPath pip install --python $PythonPath --requirements $RequirementsPath --quiet --no-progress
    if ($LASTEXITCODE -ne 0) {
        throw 'Core package installation failed. Keep the original error above; do not install every optional package as a workaround.'
    }
}
else {
    Write-Host 'uv was not found, so the pinned versions were not re-synced. The existing environment passed the import check and is used as is.'
}

Write-Host '[3/5] Checking Microsoft Word...'
$WordPath = Find-Word
if (-not $WordPath) {
    throw 'Microsoft Word was not found. It is required by the core docx2pdf workflow and cannot be installed automatically because it requires an Office license.'
}
Write-Host "Microsoft Word: $WordPath"

Write-Host '[4/5] Preparing Tesseract OCR and the Traditional Chinese model (skill/scripts/ensure_ocr.ps1)...'
# ensure_ocr.ps1 sets TESSDATA_PREFIX for this process too, so verify_core.py below can see it.
& $EnsureOcrPath

Write-Host '[5/5] Verifying core packages and file workflows...'
& $PythonPath $VerifyPath
if ($LASTEXITCODE -ne 0) {
    throw 'Core package verification failed.'
}

Write-Host ''
Write-Host 'Installation completed. Use this Python interpreter:'
Write-Host $PythonPath
