#!/usr/bin/env bash
# One-time developer setup (Server): activates repo git hooks and verifies tooling.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

git config core.hooksPath .githooks
chmod +x .githooks/* scripts/*.sh
git config pull.ff only
git config fetch.prune true
git config push.default current
git config rebase.autoStash true

echo "✔ Git hooks aktif (core.hooksPath=.githooks), pull hanya fast-forward."

missing=0
for tool in git php composer node npm gh; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "⚠ '$tool' tidak ditemukan di PATH"; missing=1
  fi
done
command -v gitleaks >/dev/null 2>&1 || echo "ℹ Opsional: pasang gitleaks agar secret terdeteksi sebelum commit (https://github.com/gitleaks/gitleaks)."

if [ ! -f apps/server/.env ] && [ -f apps/server/.env.example ]; then
  cp apps/server/.env.example apps/server/.env
  echo "✔ apps/server/.env dibuat dari .env.example (jangan commit .env)"
fi

if [ "$missing" -eq 0 ]; then echo "✔ Tooling lengkap."; fi
echo "Langkah berikutnya: ./scripts/dev-sync.sh feat/<topik-anda>"
