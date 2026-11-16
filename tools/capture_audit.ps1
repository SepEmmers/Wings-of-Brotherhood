param(
    [string]$Filter = ""
)

$ErrorActionPreference = "Stop"
$Godot = ".\tools\godot\Godot_v4.3-stable_win64.exe"
$Log = "tools\audit_run.log"
Remove-Item $Log -ErrorAction SilentlyContinue

$ArgsList = @("--windowed", "--resolution", "1280x720", "--audio-driver", "Dummy", "--path", ".", "--", "--visual-audit")
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $ArgsList += "--audit-filter=$Filter"
}

Write-Host "Capturing real GL Compatibility screenshots..."
$p = Start-Process -FilePath $Godot -ArgumentList $ArgsList -Wait -PassThru

Get-ChildItem "tools\audit_shots\*.png" -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host "CAPTURED: $($_.FullName) ($($_.Length) bytes)"
}
exit $p.ExitCode
