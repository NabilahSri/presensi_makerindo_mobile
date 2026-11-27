#!/usr/bin/env bash
# Helper script to create a Promotion PR from staging-main to main.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  echo "✖ Ada perubahan yang belum di-commit. Working tree harus bersih sebelum promosi." >&2
  exit 1
fi

echo "→ Mengambil status cabang terbaru dari origin…"
git fetch origin --prune

source_branch="staging-main"
target_branch="main"

commits_ahead=$(git rev-list --count "origin/$target_branch..origin/$source_branch" 2>/dev/null || echo 0)
if [ "$commits_ahead" -eq 0 ]; then
  echo "ℹ origin/$source_branch tidak memiliki commit baru dibandingkan origin/$target_branch."
  exit 0
fi

pr_title="chore(release): promote staging-main to main"
pr_body=$(cat <<'EOF'
## Ringkasan Promosi Rilis (staging-main -> main)

Promosi perubahan dari branch `staging-main` menuju `main` setelah verifikasi QC selesai.

### Checklist Verifikasi QC:
- [ ] Alur Web Portal (Login, Dashboard, User Management, Approval, Laporan, Sanksi) sudah diuji di `staging-main`.
- [ ] Endpoint REST API mobile dan `docs/API_CONTRACT.md` sudah terverifikasi sinkron.
- [ ] Tidak ada file `.env`, kredensial, atau migrasi destruktif yang lolos.
- [ ] Seluruh check `CI Gate`, `PR Policy`, dan `Security` berstatus hijau.
EOF
)

echo "→ Ditemukan $commits_ahead commit baru. Membuat Promotion PR…"
gh pr create \
  --base "$target_branch" \
  --head "$source_branch" \
  --title "$pr_title" \
  --body "$pr_body"

echo "✔ Promotion PR berhasil dibuat! Menunggu review dan approval."
