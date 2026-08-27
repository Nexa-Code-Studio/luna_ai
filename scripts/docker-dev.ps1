$ErrorActionPreference = 'Stop'

# Resolve repository root relative to script location
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RootDir = Split-Path -Parent $ScriptDir

Set-Location $RootDir

Write-Host "==> 🐳 Starting LUNA AI Fast Docker Environment in Windows..."

# Ensure .env file exists
$EnvFile = Join-Path $RootDir ".env"
$EnvExampleFile = Join-Path $RootDir ".env.example"
if ((-not (Test-Path $EnvFile)) -and (Test-Path $EnvExampleFile)) {
    Write-Host "==> Copying .env.example to .env..."
    Copy-Item $EnvExampleFile $EnvFile
}

# Enable Docker BuildKit for ultra-fast parallel builds & layer caching
$env:DOCKER_BUILDKIT = "1"
$env:COMPOSE_DOCKER_CLI_BUILD = "1"

# Spin up containers in detached mode with build
docker compose up -d --build

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "✅ All LUNA AI Docker containers started successfully!" -ForegroundColor Green
Write-Host "------------------------------------------------------------"
Write-Host "  • FastAPI Application  : http://localhost:8888"
Write-Host "  • FastMCP Tool Server : http://localhost:8889"
Write-Host "  • PostgreSQL Database  : localhost:5432"
Write-Host "  • Redis Cache / Queue : localhost:6379"
Write-Host "  • Qdrant Vector DB    : http://localhost:6333"
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Useful commands:"
Write-Host "  • View live logs : docker compose logs -f"
Write-Host "  • Stop containers: docker compose down"
Write-Host ""
