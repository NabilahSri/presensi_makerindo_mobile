#!/usr/bin/env bash
# Helper script to create a Promotion PR from staging-mobile to mobile.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain)" ]; then
  echo "✖ Ada perubahan yang belum di-commit. Working tree harus bersih sebelum promosi." >&2
  exit 1
fi

echo "→ Mengambil status cabang terbaru dari origin…"
git fetch origin --prune

source_branch="staging-mobile"
target_branch="mobile"

commits_ahead=$(git rev-list --count "origin/$target_branch..origin/$source_branch" 2>/dev/null || echo 0)
if [ "$commits_ahead" -eq 0 ]; then
  echo "ℹ origin/$source_branch tidak memiliki commit baru dibandingkan origin/$target_branch."
  exit 0
fi

pr_title="chore(release): promote staging-mobile to mobile"
pr_body=$(cat <<'EOF'
## Ringkasan Promosi Rilis Mobile (staging-mobile -> mobile)

Promosi perubahan dari branch `staging-mobile` menuju `mobile` setelah verifikasi QC selesai.

### Checklist Verifikasi QC:
- [ ] Alur Login, Check-in/Check-out GPS & Foto, Daily Report, Izin, dan Sanksi sudah diuji di `staging-mobile`.
- [ ] Kontrak endpoint API tetap kompatibel dengan branch `main` (`docs/API_CONTRACT.md`).
- [ ] Tidak ada file `.env`, keystore (`.jks`/`.keystore`), `key.properties`, atau kredensial di diff.
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
