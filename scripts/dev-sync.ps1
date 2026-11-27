param(
    [string]$BranchName = ""
)

$ErrorActionPreference = "Stop"

$repoRoot = (git rev-parse --show-toplevel).Trim()
Push-Location $repoRoot
try {
    $status = git status --porcelain
    if ($status) {
        throw "Ada perubahan yang belum di-commit. Commit atau stash terlebih dahulu."
    }

    if ($BranchName -and ($BranchName -notmatch '^(feat|feature|fix|chore|docs|refactor|test|hotfix)/[a-z0-9._-]+$')) {
        throw "Nama branch harus: feat|feature|fix|chore|docs|refactor|test|hotfix/<topik-huruf-kecil>"
    }

    Write-Host "-> Mengambil update terbaru dari origin..." -ForegroundColor Cyan
    git fetch origin --prune

    $baseBranch = "staging-mobile"
    git show-ref --verify --quiet "refs/remotes/origin/staging-mobile" 2>$null
    if ($LASTEXITCODE -ne 0) {
        $baseBranch = "mobile"
    }

    if ($BranchName) {
        git show-ref --verify --quiet "refs/heads/$BranchName" 2>$null
        if ($LASTEXITCODE -eq 0) {
            throw "Branch lokal '$BranchName' sudah ada. Pilih nama lain atau jalankan: git switch $BranchName"
        }

        git switch -c $BranchName "origin/$baseBranch"
        git branch --unset-upstream 2>$null | Out-Null
        Write-Host "[OK] Branch '$BranchName' dibuat dari origin/$baseBranch terbaru." -ForegroundColor Green
        Write-Host "Langkah berikutnya: .\scripts\pre-pr-check.ps1 lalu git push -u origin $BranchName" -ForegroundColor Cyan
        return
    }

    $current = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($current -in @("mobile", "staging-mobile")) {
        git show-ref --verify --quiet "refs/remotes/origin/$current" 2>$null
        if ($LASTEXITCODE -eq 0) {
            git pull --ff-only origin $current
            Write-Host "[OK] $current diperbarui." -ForegroundColor Green
        } else {
            Write-Host "[INFO] Branch origin/$current belum ada di remote." -ForegroundColor Yellow
        }
    } else {
        Write-Host "-> Menggabungkan origin/$baseBranch ke '$current'..." -ForegroundColor Cyan
        git merge --no-edit "origin/$baseBranch"
        if ($LASTEXITCODE -ne 0) {
            throw "Konflik merge terdeteksi. Selesaikan konflik, lalu git add <file> dan git commit."
        }
        Write-Host "[OK] '$current' sudah mutakhir dengan origin/$baseBranch." -ForegroundColor Green
    }
} finally {
    Pop-Location
}
