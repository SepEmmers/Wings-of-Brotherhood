param(
    [switch]$KeepLog
)

$ErrorActionPreference = "Stop"
$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Push-Location $RepoRoot

$GodotGui = Join-Path $RepoRoot "tools\godot\Godot_v4.3-stable_win64.exe"
$LogFile = "tools\godot_smoke.log"

if (Test-Path $LogFile) {
    Remove-Item $LogFile -Force
}

if (-not (Test-Path $GodotGui)) {
    Write-Error "Godot executable not found at $GodotGui"
    Pop-Location
    exit 2
}

Write-Host "Running headless multi-preset & multi-region smoke suite..." -ForegroundColor Cyan
$proc = Start-Process -FilePath $GodotGui `
    -ArgumentList @("--headless", "--verbose", "--path", ".", "--quit-after", "600", "--log-file", $LogFile, "--", "--smoke-regions") `
    -Wait -PassThru -NoNewWindow

$exitCode = $proc.ExitCode
Start-Sleep -Milliseconds 300

if (-not (Test-Path $LogFile)) {
    Write-Error "Expected log file not found at $LogFile"
    Pop-Location
    exit 1
}

$errMatches = @(Select-String -Path $LogFile -Pattern "ERROR|SCRIPT ERROR|Parse Error|SMOKE_FAIL|Failed to load")
$passMatches = @(Select-String -Path $LogFile -Pattern "SMOKE_PASS")
$stageMatches = @(Select-String -Path $LogFile -Pattern "SMOKE_STAGE")

Write-Host ("GODOT_EXIT={0} | STAGES={1} | ERRORS={2} | PASS={3}" -f $exitCode, $stageMatches.Count, $errMatches.Count, $passMatches.Count)

if ($passMatches.Count -gt 0) {
    foreach ($pm in $passMatches) {
        Write-Host $pm.Line -ForegroundColor Green
    }
}

if ($errMatches.Count -gt 0 -or $passMatches.Count -eq 0 -or $exitCode -ne 0) {
    Write-Host "Smoke test failed! Relevant log lines:" -ForegroundColor Red
    foreach ($em in ($errMatches | Select-Object -First 40)) {
        Write-Host ("  " + $em.Line) -ForegroundColor Red
    }
    Pop-Location
    exit 1
}

if (-not $KeepLog -and (Test-Path $LogFile)) {
    Remove-Item $LogFile -Force
}

Pop-Location
exit 0
