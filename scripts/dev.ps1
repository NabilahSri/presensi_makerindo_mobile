$ErrorActionPreference = "Stop"

$serverDir = Join-Path $PSScriptRoot "..\apps\server"
Push-Location $serverDir
try {
    Write-Host "Starting Laravel + Vite development server in apps/server..." -ForegroundColor Cyan
    composer run dev
} finally {
    Pop-Location
}
