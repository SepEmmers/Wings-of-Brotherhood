param(
    [switch]$Force,
    [switch]$SkipVerify,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$GodotVersion = "4.3-stable"
$ExpectedVersionPrefix = "4.3.stable"
$ExeName = "Godot_v4.3-stable_win64.exe"
$ConsoleExeName = "Godot_v4.3-stable_win64_console.exe"
$ExpectedSha512 = "ad09b7e19949327700dfbe64e35880a2a08091c0751277f5cc21b915e5df9b4fe93fb43c50d6bdfb9d16b46168592491aa698e0d2dbe9f92132e163dd77b97e1"
$DownloadUrls = @(
    "https://github.com/godotengine/godot-builds/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip",
    "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip",
    "https://downloads.godotengine.org/?version=4.3&flavor=stable&slug=win64.exe.zip&platform=windows.64"
)

$GodotDir = Join-Path $RepoRoot "tools\godot"
$GodotExe = Join-Path $GodotDir $ExeName
$VerifyLogRel = "tools\setup_verify.log"
$VerifyLogPath = Join-Path $RepoRoot $VerifyLogRel


function Test-GodotExecutable {
    param([string]$ExePath)
    if (-not (Test-Path -LiteralPath $ExePath -PathType Leaf)) {
        return $false
    }
    $tmpOut = [System.IO.Path]::GetTempFileName()
    $tmpErr = [System.IO.Path]::GetTempFileName()
    try {
        $proc = Start-Process -FilePath $ExePath `
            -ArgumentList @("--headless", "--version") `
            -Wait -PassThru `
            -RedirectStandardOutput $tmpOut `
            -RedirectStandardError $tmpErr
        $outText = ""
        if (Test-Path -LiteralPath $tmpOut) {
            $outText = (Get-Content -LiteralPath $tmpOut -Raw -ErrorAction SilentlyContinue)
            if ($null -eq $outText) { $outText = "" }
            $outText = $outText.Trim()
        }
        return ($proc.ExitCode -eq 0 -and $outText -match ("^" + [regex]::Escape($ExpectedVersionPrefix)))
    }
    catch {
        return $false
    }
    finally {
        Remove-Item -LiteralPath $tmpOut, $tmpErr -Force -ErrorAction SilentlyContinue
    }
}


function Test-LaunchedFromExplorer {
    if ($NoPause -or -not [Environment]::UserInteractive -or [Console]::IsInputRedirected) {
        return $false
    }
    try {
        $procs = @{}
        foreach ($p in (Get-CimInstance -ClassName Win32_Process -Property ProcessId, ParentProcessId, Name -ErrorAction Stop)) {
            $procs[[int]$p.ProcessId] = $p
        }
        $curPid = [int]$PID
        for ($depth = 0; $depth -lt 4; $depth++) {
            if (-not $procs.ContainsKey($curPid)) { break }
            $parentPid = [int]$procs[$curPid].ParentProcessId
            if (-not $procs.ContainsKey($parentPid)) { break }
            $parentName = [string]$procs[$parentPid].Name
            if ($parentName -ieq "explorer.exe") {
                return $true
            }
            if ($parentName -match "^(powershell|pwsh|bash|sh|code|antigravity|devenv|py|python|node|wt|WindowsTerminal)\.exe$") {
                return $false
            }
            $curPid = $parentPid
        }
    }
    catch {
        return $false
    }
    return $false
}


function Invoke-FileDownload {
    param(
        [string]$Url,
        [string]$DestPath
    )

    if (Test-Path -LiteralPath $DestPath) {
        Remove-Item -LiteralPath $DestPath -Force -ErrorAction SilentlyContinue
    }

    $curlCmd = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($null -ne $curlCmd) {
        & $curlCmd.Source -L --fail --retry 2 --connect-timeout 20 --progress-bar -o $DestPath $Url
        if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $DestPath -PathType Leaf)) {
            return $true
        }
        if (Test-Path -LiteralPath $DestPath) {
            Remove-Item -LiteralPath $DestPath -Force -ErrorAction SilentlyContinue
        }
    }

    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    }
    catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    $prevProgress = $ProgressPreference
    try {
        $ProgressPreference = "SilentlyContinue"
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -TimeoutSec 120
        }
        else {
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -TimeoutSec 120
        }
        return (Test-Path -LiteralPath $DestPath -PathType Leaf)
    }
    catch {
        if (Test-Path -LiteralPath $DestPath) {
            Remove-Item -LiteralPath $DestPath -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
    finally {
        $ProgressPreference = $prevProgress
    }
}


function Test-RepositoryIntegrity {
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "64-bit Windows is required to run Godot $GodotVersion (win64)."
    }

    $requiredFiles = @("project.godot", "scenes\Main.tscn", "run_game.bat")
    foreach ($rel in $requiredFiles) {
        $full = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
            throw "Incomplete repository clone: missing '$rel'. Run setup.bat from the repository root."
        }
    }

    $requiredDirs = @("assets\sprites", "assets\audio", "assets\hd2d", "assets\shaders")
    foreach ($rel in $requiredDirs) {
        $full = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $full -PathType Container)) {
            throw "Incomplete repository clone: missing directory '$rel'."
        }
    }

    $pngCount = (Get-ChildItem -LiteralPath (Join-Path $RepoRoot "assets\sprites") -Filter "*.png" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    $wavCount = (Get-ChildItem -LiteralPath (Join-Path $RepoRoot "assets\audio") -Filter "*.wav" -File -ErrorAction SilentlyContinue | Measure-Object).Count
    if ($pngCount -eq 0 -or $wavCount -eq 0) {
        throw "Game assets appear incomplete (found $pngCount PNG sprites and $wavCount WAV audio files). Verify git clone completed without errors."
    }
}


function Install-GodotEngine {
    if ((-not $Force) -and (Test-GodotExecutable -ExePath $GodotExe)) {
        Write-Host "[OK] Godot $GodotVersion already installed at tools\godot\$ExeName." -ForegroundColor Green
        return
    }

    if (-not (Test-Path -LiteralPath $GodotDir -PathType Container)) {
        New-Item -ItemType Directory -Path $GodotDir -Force | Out-Null
    }

    $tmpZip = Join-Path $GodotDir ".tmp_godot43.zip"
    $tmpExtract = Join-Path $GodotDir ".tmp_extract"

    try {
        if (Test-Path -LiteralPath $tmpZip) { Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $tmpExtract) { Remove-Item -LiteralPath $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue }

        $downloaded = $false
        foreach ($url in $DownloadUrls) {
            Write-Host "Downloading Godot $GodotVersion from $url ..." -ForegroundColor Yellow
            $ok = Invoke-FileDownload -Url $url -DestPath $tmpZip
            if (-not $ok) {
                Write-Warning "Download failed from $url; trying next mirror..."
                continue
            }

            $actualHash = (Get-FileHash -LiteralPath $tmpZip -Algorithm SHA512).Hash.ToLowerInvariant()
            if ($actualHash -ne $ExpectedSha512.ToLowerInvariant()) {
                Write-Warning "SHA-512 mismatch from $url (expected $ExpectedSha512, got $actualHash); trying next mirror..."
                Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue
                continue
            }

            Write-Host "[OK] Downloaded and verified SHA-512 checksum." -ForegroundColor Green
            $downloaded = $true
            break
        }

        if (-not $downloaded) {
            Write-Host ""
            Write-Host "[ERROR] Could not automatically download Godot $GodotVersion." -ForegroundColor Red
            Write-Host "Manual workaround:" -ForegroundColor Yellow
            Write-Host "  1. Download Godot_v4.3-stable_win64.exe.zip from:"
            Write-Host "     https://github.com/godotengine/godot-builds/releases/tag/4.3-stable"
            Write-Host "  2. Extract Godot_v4.3-stable_win64.exe into:"
            Write-Host "     $GodotDir"
            Write-Host "  3. Run setup.bat again (or launch run_game.bat directly)."
            throw "Automatic download of Godot $GodotVersion failed."
        }

        Write-Host "Extracting Godot $GodotVersion into tools\godot\ ..." -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $tmpExtract -Force | Out-Null
        Expand-Archive -LiteralPath $tmpZip -DestinationPath $tmpExtract -Force

        $mainExeFound = Get-ChildItem -LiteralPath $tmpExtract -Filter $ExeName -Recurse -File | Select-Object -First 1
        if ($null -eq $mainExeFound) {
            throw "Extracted archive did not contain $ExeName."
        }
        Move-Item -LiteralPath $mainExeFound.FullName -Destination $GodotExe -Force
        Unblock-File -LiteralPath $GodotExe -ErrorAction SilentlyContinue

        $consoleExeFound = Get-ChildItem -LiteralPath $tmpExtract -Filter $ConsoleExeName -Recurse -File | Select-Object -First 1
        if ($null -ne $consoleExeFound) {
            $consoleDest = Join-Path $GodotDir $ConsoleExeName
            Move-Item -LiteralPath $consoleExeFound.FullName -Destination $consoleDest -Force
            Unblock-File -LiteralPath $consoleDest -ErrorAction SilentlyContinue
        }

        if (-not (Test-GodotExecutable -ExePath $GodotExe)) {
            throw "Extracted Godot binary at $GodotExe failed '--headless --version' check."
        }
        Write-Host "[OK] Godot $GodotVersion installed and verified." -ForegroundColor Green
    }
    finally {
        Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}


function Invoke-StartupVerify {
    if ($SkipVerify) {
        Write-Host "[SKIP] Headless startup verification skipped (-SkipVerify)." -ForegroundColor Yellow
        return
    }

    if (Test-Path -LiteralPath $VerifyLogPath) {
        Remove-Item -LiteralPath $VerifyLogPath -Force -ErrorAction SilentlyContinue
    }

    Write-Host "Verifying game startup (headless)..." -ForegroundColor Cyan
    $proc = Start-Process -FilePath $GodotExe `
        -ArgumentList @("--headless", "--path", ".", "--quit-after", "3", "--log-file", $VerifyLogRel) `
        -Wait -PassThru -NoNewWindow

    Start-Sleep -Milliseconds 200
    if (-not (Test-Path -LiteralPath $VerifyLogPath -PathType Leaf)) {
        throw "Startup verification failed: expected log file '$VerifyLogRel' was not created."
    }

    $errMatches = @(Select-String -LiteralPath $VerifyLogPath -Pattern "Parse Error|SCRIPT ERROR|Failed to load script")
    if ($proc.ExitCode -ne 0 -or $errMatches.Count -gt 0) {
        Write-Host "[ERROR] Headless startup verification reported errors:" -ForegroundColor Red
        foreach ($em in ($errMatches | Select-Object -First 30)) {
            Write-Host ("  " + $em.Line) -ForegroundColor Red
        }
        throw "Game startup verification failed (exit=$($proc.ExitCode), errors=$($errMatches.Count)). See $VerifyLogRel"
    }

    Remove-Item -LiteralPath $VerifyLogPath -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Game scripts and main scene verified with 0 startup errors." -ForegroundColor Green
}


$ShouldPause = Test-LaunchedFromExplorer
$ExitCode = 0

Push-Location $RepoRoot
try {
    Write-Host "=== Wings of the Brotherhood — Setup ===" -ForegroundColor Cyan
    Write-Host "[1/3] Checking OS and repository files..." -ForegroundColor Cyan
    Test-RepositoryIntegrity
    Write-Host "[OK] Repository files and runtime assets verified." -ForegroundColor Green

    Write-Host "[2/3] Ensuring Godot $GodotVersion (win64)..." -ForegroundColor Cyan
    Install-GodotEngine

    Write-Host "[3/3] Running quick headless startup check..." -ForegroundColor Cyan
    Invoke-StartupVerify

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host " Setup complete! Game is ready to play." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  Play the game:          run_game.bat"
    Write-Host "  Optional dev tools:     run_creator_studio.bat (requires Python 3)"
    Write-Host "  Optional smoke test:    powershell -ExecutionPolicy Bypass -File tools\smoke_test.ps1"
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "[FAILED] $($_.Exception.Message)" -ForegroundColor Red
    $ExitCode = 1
}
finally {
    Pop-Location
}

if ($ShouldPause) {
    Write-Host ""
    Read-Host "Press Enter to close..." | Out-Null
}

exit $ExitCode
