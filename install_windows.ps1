[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSCommandPath
$VenvPath = Join-Path $RepoRoot '.venv'
$RequirementsPath = Join-Path $RepoRoot 'requirements-core.txt'
$VerifyPath = Join-Path $RepoRoot 'verify_core.py'
$PythonPath = Join-Path $VenvPath 'Scripts\python.exe'

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

if (-not (Test-Path -LiteralPath $RequirementsPath)) {
    throw "Missing requirements file: $RequirementsPath"
}

Write-Host '[1/4] Checking uv...'
$UvPath = Find-Uv
if (-not $UvPath) {
    $winget = Get-Command 'winget' -ErrorAction SilentlyContinue
    if (-not $winget) {
        throw 'uv and WinGet were not found. Install uv from https://docs.astral.sh/uv/ and run this script again.'
    }

    Write-Host 'Installing official astral-sh.uv with WinGet...'
    & $winget.Source install --exact --id astral-sh.uv --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "uv installation failed. WinGet exit code: $LASTEXITCODE"
    }

    $UvPath = Find-Uv
    if (-not $UvPath) {
        throw 'uv was installed, but this terminal cannot see the new PATH. Restart the Agent and run this script again.'
    }
}

Write-Host "uv: $UvPath"
Write-Host '[2/4] Creating the Python 3.12 environment...'
if (Test-Path -LiteralPath $PythonPath) {
    $ExistingVersion = & $PythonPath -c "import platform; print(platform.python_version())"
    if ($LASTEXITCODE -ne 0 -or $ExistingVersion -notmatch '^3\.12\.') {
        throw "An existing .venv uses Python $ExistingVersion. It was not removed. Rename it or choose another folder, then run this script again."
    }
    Write-Host "Reusing existing .venv (Python $ExistingVersion)."
}
else {
    & $UvPath venv --python 3.12 $VenvPath --quiet
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $PythonPath)) {
        throw 'Failed to create .venv.'
    }
}

Write-Host '[3/4] Installing core packages (optional OCR, media, and Office tools are excluded)...'
& $UvPath pip install --python $PythonPath --requirements $RequirementsPath --quiet --quiet --no-progress
if ($LASTEXITCODE -ne 0) {
    throw 'Core package installation failed. Keep the original error above; do not install every optional package as a workaround.'
}

Write-Host '[4/4] Verifying core packages...'
& $PythonPath $VerifyPath
if ($LASTEXITCODE -ne 0) {
    throw 'Core package verification failed.'
}

Write-Host ''
Write-Host 'Installation completed. Use this Python interpreter:'
Write-Host $PythonPath
