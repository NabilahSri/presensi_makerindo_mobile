#!/usr/bin/env bash
# Run the same quality gates as CI locally before opening a PR (Mobile).
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$branch" == "mobile" || "$branch" == "staging-mobile" ]]; then
  echo "✖ Anda berada di branch terlindungi '$branch'. Pindah ke branch kerja Anda dulu (mis. feat/mobile-<topik>)." >&2
  exit 1
fi

git fetch origin --quiet

base_branch="staging-mobile"
if ! git show-ref --verify --quiet "refs/remotes/origin/staging-mobile"; then
  base_branch="mobile"
fi

behind=$(git rev-list --count "HEAD..origin/$base_branch" 2>/dev/null || echo 0)
if [ "$behind" -gt 0 ]; then
  echo "✖ Branch tertinggal $behind commit dari origin/$base_branch. Jalankan: ./scripts/dev-sync.sh" >&2
  exit 1
fi

echo "→ [1/4] flutter pub get"
flutter pub get

echo "→ [2/4] dart format check (advisory)"
dart format --output=none --set-exit-if-changed . || echo "⚠ Beberapa file Dart belum mengikuti dart format. Jalankan 'dart format .' bila diperlukan."

echo "→ [3/4] flutter analyze"
flutter analyze

echo "→ [4/4] flutter test"
flutter test

echo "✔ Semua gate mobile lokal lulus 100%! Push: git push -u origin $branch  lalu buka PR: gh pr create --base $base_branch --fill"
