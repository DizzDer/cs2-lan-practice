$ErrorActionPreference = 'Stop'
$stateFile = Join-Path $PSScriptRoot '.local\server.json'
if (-not (Test-Path -LiteralPath $stateFile)) { Write-Output 'No managed server state found.'; return }
$state = Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json
$serverProc = Get-Process -Id $state.ProcessId -ErrorAction SilentlyContinue
if (-not $serverProc) { Write-Output 'Server is already stopped.'; return }
if ($serverProc.ProcessName -ne 'cs2' -or $serverProc.Path -ne $state.Executable -or $serverProc.StartTime.ToUniversalTime().ToString('o') -ne $state.StartTime) { throw 'Process identity differs. Refusing to stop another process.' }
Stop-Process -Id $serverProc.Id -ErrorAction Stop
Write-Output 'Server stopped.'
