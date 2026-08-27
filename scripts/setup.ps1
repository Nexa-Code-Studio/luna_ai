$ErrorActionPreference = 'Stop'

# Resolve repository root relative to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir

Set-Location $RootDir

Write-Host "==> Setting up local Python monorepo environment in $RootDir..."

# Create .venv if it does not exist
$VenvPath = Join-Path $RootDir ".venv"
if (-not (Test-Path $VenvPath)) {
    Write-Host "==> Creating virtual environment at .venv..."
    python -m venv .venv
} else {
    Write-Host "==> Existing virtual environment found at .venv"
}

# Activate virtual environment
Write-Host "==> Activating .venv..."
$VenvActivate = Join-Path $VenvPath "Scripts\Activate.ps1"
if (Test-Path $VenvActivate) {
    . $VenvActivate
} else {
    $env:PATH = "$(Join-Path $VenvPath 'Scripts');$env:PATH"
}

# Upgrade pip
Write-Host "==> Upgrading pip..."
python -m pip install --upgrade pip

# Install local packages in editable mode
Write-Host "==> Installing local packages using editable installs (pip install -e)..."
pip install -e "$RootDir\packages\shared"
pip install -e "$RootDir\packages\ai"
pip install -e "$RootDir\apps\backend\api"
pip install -e "$RootDir\apps\backend\mcp"
pip install -e "$RootDir\apps\backend\workers"


# Create .env from .env.example if it doesn't exist
$EnvFile = Join-Path $RootDir ".env"
$EnvExampleFile = Join-Path $RootDir ".env.example"
if ((-not (Test-Path $EnvFile)) -and (Test-Path $EnvExampleFile)) {
    Write-Host "==> Copying .env.example to .env..."
    Copy-Item $EnvExampleFile $EnvFile
}

Write-Host "==> Setup completed successfully!"
