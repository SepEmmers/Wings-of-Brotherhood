param(
    [switch]$Force,
    [switch]$SkipVerify,
    [switch]$NoPause
)

$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
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
$SetupLogPath = Join-Path $RepoRoot "tools\setup.log"
$VerifyLogRel = "tools\setup_verify.log"
$VerifyLogPath = Join-Path $RepoRoot $VerifyLogRel


function Write-Log {
    param(
        [string]$Message,
        [string]$Color = "Gray",
        [switch]$LogOnly
    )
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    try {
        Add-Content -LiteralPath $SetupLogPath -Value ("[$ts] $Message") -Encoding UTF8 -ErrorAction SilentlyContinue
    }
    catch {}
    if (-not $LogOnly) {
        if ($Color -eq "Gray") {
            Write-Host $Message
        }
        else {
            Write-Host $Message -ForegroundColor $Color
        }
    }
}


function Invoke-WithRetry {
    param(
        [scriptblock]$Action,
        [int]$MaxAttempts = 3,
        [int]$DelayMs = 1500,
        [string]$Label = "operation"
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            return (& $Action)
        }
        catch {
            if ($attempt -ge $MaxAttempts) {
                throw
            }
            Write-Log "[WARN] $Label failed (attempt $attempt/$MaxAttempts): $($_.Exception.Message) -- retrying..." -Color Yellow
            Start-Sleep -Milliseconds $DelayMs
        }
    }
}


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
        Write-Log "Godot version probe exit=$($proc.ExitCode) out='$outText'" -LogOnly
        return ($proc.ExitCode -eq 0 -and $outText -match ("^" + [regex]::Escape($ExpectedVersionPrefix)))
    }
    catch {
        Write-Log "Godot version probe exception: $($_.Exception.Message)" -LogOnly
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

    # Method 1: Built-in Windows curl.exe via Start-Process (avoids PS 5.1 stderr NativeCommandError)
    # Note: PS 5.1 Start-Process does not auto-quote array args with spaces, so pass a quoted string.
    $curlCmd = Get-Command "curl.exe" -ErrorAction SilentlyContinue
    if ($null -ne $curlCmd) {
        try {
            $curlArgStr = "-L --fail --retry 2 --connect-timeout 20 --progress-bar -o `"$DestPath`" `"$Url`""
            $p = Start-Process -FilePath $curlCmd.Source -ArgumentList $curlArgStr -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0 -and (Test-Path -LiteralPath $DestPath -PathType Leaf) -and ((Get-Item -LiteralPath $DestPath).Length -gt 1000000)) {
                return $true
            }
            Write-Log "curl.exe failed with exit code $($p.ExitCode) for $Url" -LogOnly
        }
        catch {
            Write-Log "curl.exe exception for ${Url}: $($_.Exception.Message)" -LogOnly
        }
        if (Test-Path -LiteralPath $DestPath) {
            Remove-Item -LiteralPath $DestPath -Force -ErrorAction SilentlyContinue
        }
    }

    # Enable TLS 1.2 / 1.3 for .NET HTTP clients on Windows PowerShell 5.1
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
    }
    catch {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }

    # Method 2: .NET WebClient (fast, respects system proxy, no PS 5.1 progress-bar slowdown)
    try {
        Write-Log "Falling back to .NET WebClient download..." -Color Yellow
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent", "WingsOfTheBrotherhood-Setup/1.0")
        try {
            $wc.DownloadFile($Url, $DestPath)
        }
        finally {
            $wc.Dispose()
        }
        if ((Test-Path -LiteralPath $DestPath -PathType Leaf) -and ((Get-Item -LiteralPath $DestPath).Length -gt 1000000)) {
            return $true
        }
    }
    catch {
        Write-Log "WebClient exception for ${Url}: $($_.Exception.Message)" -LogOnly
        if (Test-Path -LiteralPath $DestPath) {
            Remove-Item -LiteralPath $DestPath -Force -ErrorAction SilentlyContinue
        }
    }

    # Method 3: Invoke-WebRequest fallback
    $prevProgress = $ProgressPreference
    try {
        $ProgressPreference = "SilentlyContinue"
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -TimeoutSec 180
        }
        else {
            Invoke-WebRequest -Uri $Url -OutFile $DestPath -TimeoutSec 180
        }
        return ((Test-Path -LiteralPath $DestPath -PathType Leaf) -and ((Get-Item -LiteralPath $DestPath).Length -gt 1000000))
    }
    catch {
        Write-Log "Invoke-WebRequest exception for ${Url}: $($_.Exception.Message)" -LogOnly
        if (Test-Path -LiteralPath $DestPath) {
            Remove-Item -LiteralPath $DestPath -Force -ErrorAction SilentlyContinue
        }
        return $false
    }
    finally {
        $ProgressPreference = $prevProgress
    }
}


function Expand-ZipSafely {
    param(
        [string]$ZipPath,
        [string]$DestDir
    )
    if (Test-Path -LiteralPath $DestDir) {
        Remove-Item -LiteralPath $DestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $DestDir -Force | Out-Null

    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
        [System.IO.Compression.ZipFile]::ExtractToDirectory($ZipPath, $DestDir)
        return
    }
    catch {
        Write-Log ".NET ZipFile extraction failed ($($_.Exception.Message)); falling back to Expand-Archive..." -LogOnly
        if (Test-Path -LiteralPath $DestDir) {
            Remove-Item -LiteralPath $DestDir -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
        Expand-Archive -LiteralPath $ZipPath -DestinationPath $DestDir -Force
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
            throw "Incomplete repository clone: missing '$rel'. Run setup.bat from the extracted repository root."
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
    Write-Log "Asset check: $pngCount PNG sprites, $wavCount WAV audio files." -LogOnly
    if ($pngCount -eq 0 -or $wavCount -eq 0) {
        throw "Game assets appear incomplete (found $pngCount PNG sprites and $wavCount WAV audio files). Verify git clone or ZIP extraction completed without errors."
    }
}


function Install-GodotEngine {
    if ((-not $Force) -and (Test-GodotExecutable -ExePath $GodotExe)) {
        Write-Log "[OK] Godot $GodotVersion already installed at tools\godot\$ExeName." -Color Green
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
            Write-Log "Downloading Godot $GodotVersion from $url ..." -Color Yellow
            $ok = Invoke-FileDownload -Url $url -DestPath $tmpZip
            if (-not $ok) {
                Write-Log "[WARN] Download failed from $url; trying next mirror..." -Color Yellow
                continue
            }

            $actualHash = (Get-FileHash -LiteralPath $tmpZip -Algorithm SHA512).Hash.ToLowerInvariant()
            if ($actualHash -ne $ExpectedSha512.ToLowerInvariant()) {
                Write-Log "[WARN] SHA-512 mismatch from $url (got $actualHash); trying next mirror..." -Color Yellow
                Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue
                continue
            }

            Write-Log "[OK] Downloaded and verified SHA-512 checksum." -Color Green
            $downloaded = $true
            break
        }

        if (-not $downloaded) {
            Write-Log ""
            Write-Log "[ERROR] Could not automatically download Godot $GodotVersion." -Color Red
            Write-Log "Manual workaround:" -Color Yellow
            Write-Log "  1. Download Godot_v4.3-stable_win64.exe.zip from:"
            Write-Log "     https://github.com/godotengine/godot-builds/releases/tag/4.3-stable"
            Write-Log "  2. Extract Godot_v4.3-stable_win64.exe into:"
            Write-Log "     $GodotDir"
            Write-Log "  3. Run setup.bat again (or launch run_game.bat directly)."
            throw "Automatic download of Godot $GodotVersion failed (check internet connection or firewall)."
        }

        Write-Log "Extracting Godot $GodotVersion into tools\godot\ ..." -Color Cyan
        Invoke-WithRetry -Label "ZIP extraction" -Action {
            Expand-ZipSafely -ZipPath $tmpZip -DestDir $tmpExtract
        }

        $mainExeFound = Get-ChildItem -LiteralPath $tmpExtract -Filter $ExeName -Recurse -File | Select-Object -First 1
        if ($null -eq $mainExeFound) {
            throw "Extracted archive did not contain $ExeName."
        }

        Invoke-WithRetry -Label "Moving $ExeName" -Action {
            Move-Item -LiteralPath $mainExeFound.FullName -Destination $GodotExe -Force
        }
        Unblock-File -LiteralPath $GodotExe -ErrorAction SilentlyContinue

        $consoleExeFound = Get-ChildItem -LiteralPath $tmpExtract -Filter $ConsoleExeName -Recurse -File | Select-Object -First 1
        if ($null -ne $consoleExeFound) {
            $consoleDest = Join-Path $GodotDir $ConsoleExeName
            Invoke-WithRetry -Label "Moving $ConsoleExeName" -Action {
                Move-Item -LiteralPath $consoleExeFound.FullName -Destination $consoleDest -Force
            }
            Unblock-File -LiteralPath $consoleDest -ErrorAction SilentlyContinue
        }

        $verified = Invoke-WithRetry -Label "Godot version verification" -Action {
            if (-not (Test-GodotExecutable -ExePath $GodotExe)) {
                throw "Godot binary at $GodotExe did not respond with $ExpectedVersionPrefix."
            }
            return $true
        }
        if ($verified) {
            Write-Log "[OK] Godot $GodotVersion installed and verified." -Color Green
        }
    }
    finally {
        Remove-Item -LiteralPath $tmpZip -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tmpExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
}


function Invoke-StartupVerify {
    if ($SkipVerify) {
        Write-Log "[SKIP] Headless startup verification skipped (-SkipVerify)." -Color Yellow
        return
    }

    if (Test-Path -LiteralPath $VerifyLogPath) {
        Remove-Item -LiteralPath $VerifyLogPath -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Verifying game startup (headless)..." -Color Cyan
    $proc = Start-Process -FilePath $GodotExe `
        -ArgumentList @("--headless", "--path", ".", "--quit-after", "3", "--log-file", $VerifyLogRel) `
        -Wait -PassThru -NoNewWindow

    Start-Sleep -Milliseconds 300
    if (-not (Test-Path -LiteralPath $VerifyLogPath -PathType Leaf)) {
        throw "Startup verification failed: expected log file '$VerifyLogRel' was not created."
    }

    $errMatches = @(Select-String -LiteralPath $VerifyLogPath -Pattern "Parse Error|SCRIPT ERROR|Failed to load script")
    if ($proc.ExitCode -ne 0 -or $errMatches.Count -gt 0) {
        Write-Log "[ERROR] Headless startup verification reported errors:" -Color Red
        foreach ($em in ($errMatches | Select-Object -First 30)) {
            Write-Log ("  " + $em.Line) -Color Red
        }
        throw "Game startup verification failed (exit=$($proc.ExitCode), errors=$($errMatches.Count)). See $VerifyLogRel"
    }

    Remove-Item -LiteralPath $VerifyLogPath -Force -ErrorAction SilentlyContinue
    Write-Log "[OK] Game scripts and main scene verified with 0 startup errors." -Color Green
}


$ShouldPause = Test-LaunchedFromExplorer
$ExitCode = 0

try {
    if (Test-Path -LiteralPath $SetupLogPath) {
        Remove-Item -LiteralPath $SetupLogPath -Force -ErrorAction SilentlyContinue
    }
    Write-Log "=== Wings of the Brotherhood - Setup ===" -Color Cyan
    Write-Log ("Environment: OS=" + [Environment]::OSVersion.VersionString + " 64bit=" + [Environment]::Is64BitOperatingSystem + " PS=" + $PSVersionTable.PSVersion.ToString() + " Repo=" + $RepoRoot) -LogOnly
}
catch {}

Push-Location -LiteralPath $RepoRoot
try {
    Write-Log "[1/3] Checking OS and repository files..." -Color Cyan
    Test-RepositoryIntegrity
    Write-Log "[OK] Repository files and runtime assets verified." -Color Green

    Write-Log "[2/3] Ensuring Godot $GodotVersion (win64)..." -Color Cyan
    Install-GodotEngine

    Write-Log "[3/3] Running quick headless startup check..." -Color Cyan
    Invoke-StartupVerify

    Write-Log ""
    Write-Log "========================================" -Color Green
    Write-Log " Setup complete! Game is ready to play." -Color Green
    Write-Log "========================================" -Color Green
    Write-Log "  Play the game:          run_game.bat"
    Write-Log "  Optional dev tools:     run_creator_studio.bat (requires Python 3)"
    Write-Log "  Optional smoke test:    powershell -ExecutionPolicy Bypass -File tools\smoke_test.ps1"
    Write-Log ""
    Remove-Item -LiteralPath $SetupLogPath -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Log ""
    Write-Log "[FAILED] $($_.Exception.Message)" -Color Red
    Write-Log ("StackTrace: " + $_.ScriptStackTrace) -LogOnly
    $ExitCode = 1
}
finally {
    Pop-Location
}

if ($ShouldPause -and $ExitCode -eq 0) {
    Write-Host ""
    Read-Host "Press Enter to close..." | Out-Null
}

exit $ExitCode
