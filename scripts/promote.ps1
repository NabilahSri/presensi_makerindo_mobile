$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
Push-Location $repoRoot
try {
    $status = git status --porcelain
    if ($status) {
        throw "Working tree belum bersih. Commit atau stash perubahan sebelum promosi."
    }

    Write-Host "-> Mengambil status branch terbaru dari origin..." -ForegroundColor Cyan
    git fetch origin --prune

    $sourceBranch = "staging-main"
    $targetBranch = "main"

    $commitsAhead = [int](git rev-list --count "origin/$targetBranch..origin/$sourceBranch" 2>$null)
    if ($commitsAhead -eq 0) {
        Write-Host "[INFO] origin/$sourceBranch tidak memiliki commit baru dibandingkan origin/$targetBranch." -ForegroundColor Yellow
        return
    }

    $prTitle = "chore(release): promote staging-main to main"
    $prBody = @"
## Ringkasan Promosi Rilis (staging-main -> main)

Promosi perubahan dari branch ``staging-main`` menuju ``main`` setelah verifikasi QC selesai.

### Checklist Verifikasi QC:
- [ ] Alur Web Portal (Login, Dashboard, User Management, Approval, Laporan, Sanksi) sudah diuji di ``staging-main``.
- [ ] Endpoint REST API mobile dan ``docs/API_CONTRACT.md`` sudah terverifikasi sinkron.
- [ ] Tidak ada file ``.env``, kredensial, atau migrasi destruktif yang lolos.
- [ ] Seluruh check ``CI Gate``, ``PR Policy``, dan ``Security`` berstatus hijau.
"@

    Write-Host "-> Ditemukan $commitsAhead commit baru. Membuat Promotion PR..." -ForegroundColor Cyan
    gh pr create --base $targetBranch --head $sourceBranch --title $prTitle --body $prBody
    if ($LASTEXITCODE -ne 0) { throw "Gagal membuat Promotion PR." }

    Write-Host "[OK] Promotion PR staging-main -> main berhasil dibuat." -ForegroundColor Green
} finally {
    Pop-Location
}
