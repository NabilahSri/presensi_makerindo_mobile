# AGENTS.md — Pedoman Pengembangan Branch `mobile` (Flutter)

Dokumen ini menjadi acuan bagi developer dan AI coding agent saat bekerja di repository `NabilahSri/presensi_makerindo_mobile` pada track mobile (`mobile` & `staging-mobile`).

---

## 0. Wajib Baca Sebelum Menulis Kode (Pre-Flight `.agents/`)

Sebelum merencanakan, mengubah, atau membuat kode Dart/Flutter:
1. [`docs/MOBILE_GUIDE.md`](docs/MOBILE_GUIDE.md) — Setup Flutter, konfigurasi `ApiService`, versi, & build aman.
2. [`CONTRIBUTING.md`](CONTRIBUTING.md) — Alur kerja branch `staging-mobile -> mobile`, hooks, & CI gate.
3. [`SECURITY.md`](SECURITY.md) — Keamanan token lokal, GPS/kamera, dan larangan commit keystore.
4. [`.agents/README.md`](.agents/README.md) — Daftar rules (`.agents/rules/`) dan skill resmi (`.agents/skills/`).

---

## 1. Aturan Utama

1. Branch `mobile` dan `staging-mobile` khusus untuk aplikasi **Flutter Mobile** (`lib/`, `android/`, `ios/`, `test/`, `pubspec.yaml`).
2. Jangan menaruh file backend/web Laravel di branch `mobile` / `staging-mobile` — seluruh kode Web & REST API ada di track `main` (`apps/server/`).
3. Sebelum mengubah model di `lib/models/models.dart` atau panggilan endpoint di `lib/services/api_service.dart`, pastikan kontrak endpoint di branch `main` (`apps/server/routes/api.php`, `routes/web.php`, dan `docs/API_CONTRACT.md`) sudah sesuai.
4. Jalankan `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, dan `flutter test` sebelum commit/push (atau jalankan `.\scripts\pre-pr-check.ps1`).
5. Gunakan Conventional Commits (`feat(mobile): ...`, `fix(mobile): ...`, `docs(mobile): ...`), satu perubahan logis per commit, stage file secara eksplisit (`git add <file...>`), dan **tanpa atribusi AI** (`Co-Authored-By`, `Generated with/by`).
6. Dilarang melakukan direct push atau force-push ke `mobile` dan `staging-mobile`. Seluruh perubahan fitur/fix masuk ke `staging-mobile` melalui PR, lalu dipromosikan ke `mobile`.
7. Jangan pernah meng-commit `.env*`, file keystore (`.jks`, `.keystore`), `android/key.properties`, `google-services.json`, atau `GoogleService-Info.plist`.
8. Jangan menghapus file, direktori, atau branch secara destruktif tanpa konfirmasi eksplisit pemilik repositori.
