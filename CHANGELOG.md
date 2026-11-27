# Changelog (Mobile Client)

Seluruh perubahan penting pada track mobile (`mobile`) dicatat pada berkas ini.

Format mengikuti [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
dan proyek ini menerapkan [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Standarisasi tata kelola GitHub (`.github/CODEOWNERS`, `dependabot.yml`, `ISSUE_TEMPLATE`, `pr-policy.yml`, `security.yml`, `release.yml`, `CI Gate`).
- Alur staging `staging-mobile -> mobile` beserta git hooks lokal (`.githooks/`) dan skrip otomasi (`scripts/`).
- Dokumentasi standar (`CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `LICENSE`, dan `.agents/`).

## [1.0.0] - 2026-11-25

### Added
- Aplikasi klien mobile Flutter untuk Presensi Makerindo (`lib/`, `android/`, `ios/`).
- Fitur Login Bearer Token, Splash Screen, Dashboard, Check-in/Check-out GPS & Foto, Daily Report pagi & sore, Perizinan & Approval, Riwayat Presensi, Sanksi, dan Profil.
