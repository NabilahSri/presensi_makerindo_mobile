$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
Push-Location $repoRoot
try {
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($branch -in @("main", "staging-main")) {
        throw "Anda berada di branch terlindungi '$branch'. Pindah ke branch kerja terlebih dahulu (mis. feat/<topik>)."
    }

    git fetch origin --quiet

    $baseBranch = "staging-main"
    git show-ref --verify --quiet "refs/remotes/origin/staging-main" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $baseBranch = "main"
    }

    $behind = [int](git rev-list --count "HEAD..origin/$baseBranch" 2>$null)
    if ($behind -gt 0) {
        throw "Branch tertinggal $behind commit dari origin/$baseBranch. Jalankan: .\scripts\dev-sync.ps1"
    }

    Write-Host "-> [1/5] Pemeriksaan sintaks PHP (php -l)" -ForegroundColor Cyan
    $changedPhp = git diff --name-only "origin/$baseBranch...HEAD" | Where-Object { $_ -match '\.php$' }
    if ($changedPhp) {
        foreach ($file in $changedPhp) {
            if (Test-Path $file) {
                php -l $file | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    throw "Kesalahan sintaks PHP pada $file"
                }
            }
        }
        Write-Host "[OK] Sintaks PHP valid." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Tidak ada perubahan file PHP." -ForegroundColor DarkGray
    }

    Write-Host "-> [2/5] Laravel Pint (style check)" -ForegroundColor Cyan
    npm run lint
    if ($LASTEXITCODE -ne 0) { throw "Laravel Pint gagal." }

    Write-Host "-> [3/5] Composer audit (vulnerability check)" -ForegroundColor Cyan
    composer --working-dir=apps/server audit --locked --no-interaction
    if ($LASTEXITCODE -ne 0) { throw "Composer audit gagal." }

    Write-Host "-> [4/5] Build frontend (Vite + Tailwind v4)" -ForegroundColor Cyan
    npm run build
    if ($LASTEXITCODE -ne 0) { throw "Vite build gagal." }

    Write-Host "-> [5/5] PHPUnit (test suite)" -ForegroundColor Cyan
    npm test
    if ($LASTEXITCODE -ne 0) { throw "PHPUnit test suite gagal." }

    Write-Host "[OK] Semua quality gate lokal lulus 100%!" -ForegroundColor Green
    Write-Host "Push: git push -u origin $branch  lalu buka PR: gh pr create --base $baseBranch --fill" -ForegroundColor Cyan
} finally {
    Pop-Location
}
