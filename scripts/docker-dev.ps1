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

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "🚀 Starting LUNA AI Interactive Docker Environment" -ForegroundColor Green
Write-Host "------------------------------------------------------------"
Write-Host "  • FastAPI Application  : http://localhost:8888"
Write-Host "  • FastMCP Tool Server : http://localhost:8889"
Write-Host "  • PostgreSQL Database  : localhost:5432"
Write-Host "  • Redis Cache / Queue : localhost:6379"
Write-Host "  • Qdrant Vector DB    : http://localhost:6333"
Write-Host "============================================================" -ForegroundColor Green
Write-Host "💡 Press Ctrl+C at any time to stop all services automatically." -ForegroundColor Yellow
Write-Host ""

try {
    # Run docker compose in foreground mode to stream colored logs directly to terminal
    docker compose up $args
} finally {
    Write-Host ""
    Write-Host "🛑 [STOPPING DOCKER]: Shutting down all LUNA AI containers..." -ForegroundColor Yellow
    docker compose down
    Write-Host "✅ All containers stopped cleanly." -ForegroundColor Green
}
