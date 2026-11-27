$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    git config pull.ff only
    git config fetch.prune true
    git config push.default current
    git config rebase.autoStash true

    Write-Host "[OK] Git hooks aktif (core.hooksPath=.githooks), pull hanya fast-forward." -ForegroundColor Green

    $missing = $false
    foreach ($tool in @("git", "php", "composer", "node", "npm", "gh")) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Host "[WARN] '$tool' tidak ditemukan di PATH" -ForegroundColor Yellow
            $missing = $true
        }
    }

    if (-not (Get-Command "gitleaks" -ErrorAction SilentlyContinue)) {
        Write-Host "[INFO] Opsional: pasang gitleaks agar secret terdeteksi sebelum commit (https://github.com/gitleaks/gitleaks)." -ForegroundColor Cyan
    }

    $envFile = Join-Path $repoRoot "apps\server\.env"
    $envExample = Join-Path $repoRoot "apps\server\.env.example"
    if (-not (Test-Path $envFile) -and (Test-Path $envExample)) {
        Copy-Item $envExample $envFile
        Write-Host "[OK] apps\server\.env dibuat dari .env.example (jangan commit .env)." -ForegroundColor Green
    }

    if (-not $missing) {
        Write-Host "[OK] Tooling lengkap." -ForegroundColor Green
    }

    Write-Host "Langkah berikutnya: .\scripts\dev-sync.ps1 feat/<topik-anda>" -ForegroundColor Cyan
} finally {
    Pop-Location
}
