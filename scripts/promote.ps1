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

    $sourceBranch = "staging-mobile"
    $targetBranch = "mobile"

    $commitsAhead = [int](git rev-list --count "origin/$targetBranch..origin/$sourceBranch" 2>$null)
    if ($commitsAhead -eq 0) {
        Write-Host "[INFO] origin/$sourceBranch tidak memiliki commit baru dibandingkan origin/$targetBranch." -ForegroundColor Yellow
        return
    }

    $prTitle = "chore(release): promote staging-mobile to mobile"
    $prBody = @"
## Ringkasan Promosi Rilis Mobile (staging-mobile -> mobile)

Promosi perubahan dari branch ``staging-mobile`` menuju ``mobile`` setelah verifikasi QC selesai.

### Checklist Verifikasi QC:
- [ ] Alur Login, Check-in/Check-out GPS & Foto, Daily Report, Izin, dan Sanksi sudah diuji di ``staging-mobile``.
- [ ] Kontrak endpoint API tetap kompatibel dengan branch ``main`` (``docs/API_CONTRACT.md``).
- [ ] Tidak ada file ``.env``, keystore (``.jks``/``.keystore``), ``key.properties``, atau kredensial di diff.
- [ ] Seluruh check ``CI Gate``, ``PR Policy``, dan ``Security`` berstatus hijau.
"@

    Write-Host "-> Ditemukan $commitsAhead commit baru. Membuat Promotion PR..." -ForegroundColor Cyan
    gh pr create --base $targetBranch --head $sourceBranch --title $prTitle --body $prBody
    if ($LASTEXITCODE -ne 0) { throw "Gagal membuat Promotion PR." }

    Write-Host "[OK] Promotion PR staging-mobile -> mobile berhasil dibuat." -ForegroundColor Green
} finally {
    Pop-Location
}
