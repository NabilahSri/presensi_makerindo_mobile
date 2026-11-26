$ErrorActionPreference = "Stop"

$serverDir = Join-Path $PSScriptRoot "..\apps\server"
Push-Location $serverDir
try {
    Write-Host "[1/5] Installing Composer dependencies..." -ForegroundColor Cyan
    composer install

    if (-not (Test-Path ".env")) {
        Write-Host "[2/5] Copying .env.example to .env..." -ForegroundColor Cyan
        Copy-Item ".env.example" ".env"
        php artisan key:generate
    } else {
        Write-Host "[2/5] .env already exists, skipping copy." -ForegroundColor Yellow
    }

    if (-not (Test-Path "database\database.sqlite")) {
        Write-Host "[3/5] Creating SQLite database file..." -ForegroundColor Cyan
        New-Item -ItemType File -Path "database\database.sqlite" -Force | Out-Null
    }

    Write-Host "[4/5] Running database migrations..." -ForegroundColor Cyan
    php artisan migrate --force

    Write-Host "[5/5] Installing NPM dependencies and building frontend assets..." -ForegroundColor Cyan
    npm install
    npm run build

    Write-Host "Setup complete! Run .\scripts\dev.ps1 to start local development." -ForegroundColor Green
} finally {
    Pop-Location
}
