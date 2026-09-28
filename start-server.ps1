param(
    [Parameter(Mandatory=$true)][string]$GameDirectory,
    [ValidatePattern('^[a-zA-Z0-9_-]+$')][string]$Map = 'de_dust2',
    [ValidateRange(1024,65535)][int]$Port = 27025,
    [ValidatePattern('^[a-zA-Z0-9_-]{8,64}$')][string]$Password = ([guid]::NewGuid().ToString('N').Substring(0,16))
)
$ErrorActionPreference = 'Stop'
$serverExe = Join-Path $GameDirectory 'game\bin\win64\cs2.exe'
if (-not (Test-Path -LiteralPath $serverExe)) { throw 'CS2 executable not found in GameDirectory.' }
$serverExe = (Resolve-Path -LiteralPath $serverExe).Path
$stateDir = Join-Path $PSScriptRoot '.local'
New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
$stateFile = Join-Path $stateDir 'server.json'
if (Test-Path -LiteralPath $stateFile) {
    $previous = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
    $existing = Get-Process -Id $previous.ProcessId -ErrorAction SilentlyContinue
    if ($existing -and $existing.StartTime.ToUniversalTime().ToString('o') -eq $previous.StartTime) { throw 'Managed server is already running.' }
}
if (netstat -ano -p udp | Select-String ":$Port\s") { throw "UDP port $Port is already in use." }
$serverArgs = "-dedicated -console -port $Port +sv_lan 1 +hostname `"CS2 LAN Practice`" +sv_password $Password +game_type 0 +game_mode 0 +map $Map +bot_quota 0"
$serverProc = Start-Process -FilePath $serverExe -WorkingDirectory (Split-Path $serverExe) -ArgumentList $serverArgs -WindowStyle Hidden -RedirectStandardOutput (Join-Path $stateDir 'stdout.log') -RedirectStandardError (Join-Path $stateDir 'stderr.log') -PassThru
@{ ProcessId=$serverProc.Id; StartTime=$serverProc.StartTime.ToUniversalTime().ToString('o'); Executable=$serverExe } | ConvertTo-Json | Set-Content -LiteralPath $stateFile
Start-Sleep -Seconds 3
$serverProc.Refresh()
if ($serverProc.HasExited) { throw 'Server exited. Check .local/stdout.log and stderr.log.' }
Write-Output "Server process started. Map loading may still be in progress. PID: $($serverProc.Id)"
Write-Output "In your CS2 console: password $Password; connect 127.0.0.1:$Port"
Write-Output "Friends: use your LAN IPv4 address instead of 127.0.0.1. Logs: $stateDir"
