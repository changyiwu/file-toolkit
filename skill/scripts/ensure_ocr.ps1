[CmdletBinding()]
param()

# Install and configure Tesseract OCR with the Traditional Chinese model.
# Run this once before OCR-ing scanned PDFs.
# Keep this file ASCII-only: Windows PowerShell 5.1 reads BOM-less UTF-8 as ANSI.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Find-Tesseract {
    $command = Get-Command 'tesseract' -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }

    $candidates = @(
        (Join-Path ([Environment]::GetFolderPath('ProgramFiles')) 'Tesseract-OCR\tesseract.exe'),
        (Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Tesseract-OCR\tesseract.exe')
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    return $null
}

Write-Host '[1/3] Checking Tesseract OCR...'
$TesseractPath = Find-Tesseract
if (-not $TesseractPath) {
    $WinGet = Get-Command 'winget' -ErrorAction SilentlyContinue
    if (-not $WinGet) {
        throw 'Tesseract OCR and WinGet were not found. Install UB-Mannheim.TesseractOCR and run this script again.'
    }
    Write-Host 'Installing Tesseract OCR with WinGet...'
    & $WinGet.Source install --exact --id UB-Mannheim.TesseractOCR --silent --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        throw "Tesseract OCR installation failed. WinGet exit code: $LASTEXITCODE"
    }
    $TesseractPath = Find-Tesseract
    if (-not $TesseractPath) {
        throw 'Tesseract OCR was installed, but its executable was not found. Restart the Agent and run this script again.'
    }
}
Write-Host "Tesseract OCR: $TesseractPath"

# Models cannot be written into Program Files, so keep them under the user profile.
Write-Host '[2/3] Configuring English, orientation, and Traditional Chinese OCR data...'
$SourceTessData = Join-Path (Split-Path -Parent $TesseractPath) 'tessdata'
$TessData = Join-Path $env:LOCALAPPDATA 'Tesseract-OCR\tessdata'
New-Item -ItemType Directory -Path $TessData -Force | Out-Null

foreach ($fileName in @('eng.traineddata', 'osd.traineddata', 'pdf.ttf')) {
    $sourceFile = Join-Path $SourceTessData $fileName
    if (-not (Test-Path -LiteralPath $sourceFile)) {
        throw "Missing Tesseract data file: $sourceFile"
    }
    Copy-Item -LiteralPath $sourceFile -Destination $TessData -Force
}

foreach ($folderName in @('configs', 'tessconfigs')) {
    $sourceFolder = Join-Path $SourceTessData $folderName
    $targetFolder = Join-Path $TessData $folderName
    if (-not (Test-Path -LiteralPath $sourceFolder)) {
        throw "Missing Tesseract configuration folder: $sourceFolder"
    }
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
    Get-ChildItem -LiteralPath $sourceFolder -File | Copy-Item -Destination $targetFolder -Force
}

$ChiTraPath = Join-Path $TessData 'chi_tra.traineddata'
$ChiTraHash = '529C5B5797D64B126065CD55F2BB4C7FD7B15790798091B1FF259941A829330B'
$ChiTraUrl = 'https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/87416418657359cb625c412a48b6e1d6d41c29bd/chi_tra.traineddata'

$NeedsDownload = -not (Test-Path -LiteralPath $ChiTraPath)
if (-not $NeedsDownload) {
    $NeedsDownload = (Get-FileHash -Algorithm SHA256 -LiteralPath $ChiTraPath).Hash -ne $ChiTraHash
}
if ($NeedsDownload) {
    $TemporaryPath = "$ChiTraPath.download"
    try {
        Invoke-WebRequest -Uri $ChiTraUrl -OutFile $TemporaryPath
        $DownloadedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $TemporaryPath).Hash
        if ($DownloadedHash -ne $ChiTraHash) {
            throw "Traditional Chinese OCR data hash mismatch: $DownloadedHash"
        }
        Move-Item -LiteralPath $TemporaryPath -Destination $ChiTraPath -Force
    }
    finally {
        if (Test-Path -LiteralPath $TemporaryPath) {
            Remove-Item -LiteralPath $TemporaryPath -Force
        }
    }
}

$env:TESSDATA_PREFIX = $TessData
[Environment]::SetEnvironmentVariable('TESSDATA_PREFIX', $TessData, 'User')

Write-Host '[3/3] Verifying the Traditional Chinese model...'
$Languages = & $TesseractPath --list-langs 2>&1
if ($Languages -notcontains 'chi_tra') {
    throw "chi_tra is still missing from: $TessData"
}

Write-Host "Tesseract data: $TessData"
Write-Host 'OCR is ready. Use lang chi_tra+eng for Traditional Chinese handouts.'
