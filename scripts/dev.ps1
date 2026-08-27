$ErrorActionPreference = 'Stop'

# Resolve repository root relative to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir

Set-Location $RootDir

$VenvPath = Join-Path $RootDir ".venv"
if (-not (Test-Path $VenvPath)) {
    Write-Error "Virtual environment '.venv' not found. Please run .\scripts\setup.ps1 first."
    exit 1
}

$VenvActivate = Join-Path $VenvPath "Scripts\Activate.ps1"

$services = @(
    @{
        Name = "FastAPI Application Server"
        Path = Join-Path $RootDir "apps\backend\api"
        Command = "uvicorn app.main:app --reload --port 8888"

    },
    @{
        Name = "FastMCP AI Tool Server"
        Path = Join-Path $RootDir "apps\backend\mcp"
        Command = "python -m app.main"
    },
    @{
        Name = "ARQ Worker"
        Path = Join-Path $RootDir "apps\backend\workers"
        Command = "arq app.workers.settings.WorkerSettings"
    }
)

foreach ($service in $services) {
    Write-Host "==> Starting $($service.Name)..."
    $scriptBlock = "Set-Location '$($service.Path)'; `$env:PYTHONPATH='$RootDir;.'; if (Test-Path '$VenvActivate') { . '$VenvActivate' } else { `$env:PATH = '$(Join-Path $VenvPath 'Scripts');' + `$env:PATH }; $($service.Command)"
    Start-Process powershell -ArgumentList "-NoExit", "-Command", $scriptBlock
}


Write-Host "==> All backend services started in separate PowerShell windows."
