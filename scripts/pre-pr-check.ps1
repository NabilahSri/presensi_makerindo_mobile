$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
Push-Location $repoRoot
try {
    $branch = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($branch -in @("mobile", "staging-mobile")) {
        throw "Anda berada di branch terlindungi '$branch'. Pindah ke branch kerja terlebih dahulu (mis. feat/mobile-<topik>)."
    }

    git fetch origin --quiet

    $baseBranch = "staging-mobile"
    git show-ref --verify --quiet "refs/remotes/origin/staging-mobile" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $baseBranch = "mobile"
    }

    $behind = [int](git rev-list --count "HEAD..origin/$baseBranch" 2>$null)
    if ($behind -gt 0) {
        throw "Branch tertinggal $behind commit dari origin/$baseBranch. Jalankan: .\scripts\dev-sync.ps1"
    }

    Write-Host "-> [1/4] flutter pub get" -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get gagal." }

    Write-Host "-> [2/4] dart format check (advisory)" -ForegroundColor Cyan
    dart format --output=none --set-exit-if-changed .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[WARN] Beberapa file Dart belum mengikuti dart format. Jalankan 'dart format .' bila diperlukan." -ForegroundColor Yellow
    }

    Write-Host "-> [3/4] flutter analyze" -ForegroundColor Cyan
    flutter analyze
    if ($LASTEXITCODE -ne 0) { throw "flutter analyze gagal." }

    Write-Host "-> [4/4] flutter test" -ForegroundColor Cyan
    flutter test
    if ($LASTEXITCODE -ne 0) { throw "flutter test gagal." }

    Write-Host "[OK] Semua quality gate mobile lokal lulus 100%!" -ForegroundColor Green
    Write-Host "Push: git push -u origin $branch  lalu buka PR: gh pr create --base $baseBranch --fill" -ForegroundColor Cyan
} finally {
    Pop-Location
}
