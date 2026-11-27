#!/usr/bin/env bash
# Pull the latest staging-main (or main) branch and start or refresh your work branch.
# Usage:
#   ./scripts/dev-sync.sh feat/nama-topik
#   ./scripts/dev-sync.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

target="${1:-}"
current=$(git rev-parse --abbrev-ref HEAD)

if [ -n "$(git status --porcelain)" ]; then
  echo "✖ Ada perubahan yang belum di-commit. Commit atau stash dulu." >&2
  exit 1
fi

if [ -n "$target" ] && ! echo "$target" | grep -qE '^(feat|feature|fix|chore|docs|refactor|test|hotfix)/[a-z0-9._-]+$'; then
  echo "✖ Nama branch harus: feat|feature|fix|chore|docs|refactor|test|hotfix/<topik-huruf-kecil>" >&2
  exit 1
fi

echo "→ Mengambil update terbaru dari origin…"
git fetch origin --prune

base_branch="staging-main"
if ! git show-ref --verify --quiet "refs/remotes/origin/staging-main"; then
  base_branch="main"
fi

if [ -n "$target" ]; then
  if git show-ref --verify --quiet "refs/heads/$target"; then
    echo "✖ Branch lokal '$target' sudah ada. Pilih nama lain atau: git switch $target" >&2
    exit 1
  fi
  git switch -c "$target" "origin/$base_branch"
  git branch --unset-upstream 2>/dev/null || true
  echo "✔ Branch '$target' dibuat dari origin/$base_branch terbaru."
  echo "  Kerjakan, commit (Conventional Commits), lalu: ./scripts/pre-pr-check.sh && git push -u origin $target"
  exit 0
fi

if [[ "$current" == "main" || "$current" == "staging-main" ]]; then
  if git show-ref --verify --quiet "refs/remotes/origin/$current"; then
    git pull --ff-only origin "$current"
    echo "✔ $current diperbarui."
  else
    echo "ℹ Branch origin/$current belum ada di remote."
  fi
else
  echo "→ Menggabungkan origin/$base_branch ke '$current'…"
  git merge --no-edit "origin/$base_branch" || {
    echo "✖ Konflik. Selesaikan konflik, lalu 'git add <file>' dan 'git commit'." >&2
    exit 1
  }
  echo "✔ '$current' sudah mutakhir dengan origin/$base_branch."
fi
