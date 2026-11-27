# Changelog (Server & Web Portal)

Seluruh perubahan penting pada track server (`main` / `apps/server`) dicatat pada berkas ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
dan proyek ini menerapkan [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Standarisasi tata kelola GitHub (`.github/CODEOWNERS`, `dependabot.yml`, `ISSUE_TEMPLATE`, `pr-policy.yml`, `security.yml`, `release.yml`, `CI Gate`).
- Alur staging `staging-main -> main` beserta git hooks lokal (`.githooks/`) dan skrip otomasi (`scripts/`).
- Dokumentasi standar (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `LICENSE`, dan `.agents/`).

## [1.0.0] - 2026-11-25

### Added
- Monorepo workspace (`apps/server`) berbasis Laravel 13, Blade + Tailwind CSS v4 + Vite 8.
- Web Portal untuk peran `super_admin`, `ceo`, dan approver perizinan (`can_approve_leaves`), serta REST API mobile (`/api/...`) untuk `karyawan` dan `intern`.
- Fitur presensi GPS & Foto (On-Site, WFA, Tugas Luar), Daily Report pagi & sore, Perizinan, Sanksi kedisiplinan (PDF), Laporan Excel (`.xlsx`), dan Hari Libur kerja.
