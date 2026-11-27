#!/usr/bin/env bash
# Run the same quality gates as CI locally before opening a PR (Server).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "main" || "$branch" == "staging-main" ]]; then
  echo "✖ Anda berada di branch terlindungi '$branch'. Pindah ke branch kerja Anda dulu (mis. feat/<topik>)." >&2
  exit 1
fi

git fetch origin --quiet

base_branch="staging-main"
if ! git show-ref --verify --quiet "refs/remotes/origin/staging-main"; then
  base_branch="main"
fi

behind=$(git rev-list --count "HEAD..origin/$base_branch" 2>/dev/null || echo 0)
if [ "$behind" -gt 0 ]; then
  echo "✖ Branch tertinggal $behind commit dari origin/$base_branch. Jalankan: ./scripts/dev-sync.sh" >&2
  exit 1
fi

echo "→ [1/5] Pemeriksaan sintaks PHP (php -l)"
modified_php=$(git diff --name-only "origin/$base_branch...HEAD" | grep -E '\.php$' || true)
if [ -n "$modified_php" ]; then
  for f in $modified_php; do
    if [ -f "$f" ]; then
      php -l "$f" >/dev/null || {
        echo "✖ Kesalahan sintaks pada $f" >&2
        exit 1
      }
    fi
  done
  echo "✔ Sintaks PHP aman."
else
  echo "ℹ Tidak ada file PHP yang berubah untuk diverifikasi."
fi

echo "→ [2/5] Laravel Pint (style check)"
npm run lint

echo "→ [3/5] Composer audit (vulnerability check)"
composer --working-dir=apps/server audit --locked --no-interaction

echo "→ [4/5] Build frontend (Vite + Tailwind v4)"
npm run build

echo "→ [5/5] PHPUnit (test suite)"
npm test

echo "✔ Semua gate lokal lulus 100%! Push: git push -u origin $branch  lalu buka PR: gh pr create --base $base_branch --fill"
