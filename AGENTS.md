# AGENTS.md — Pedoman Pengembangan Branch `mobile` (Flutter)

Dokumen ini menjadi acuan bagi developer dan AI coding agent saat bekerja di branch `mobile` (`D:\presensi_makerindo\mobile`).

## 1. Aturan Branch

1. Branch `mobile` khusus untuk aplikasi **Flutter Mobile** (`lib/`, `android/`, `ios/`, `test/`, `pubspec.yaml`).
2. Jangan menaruh file backend/web Laravel di branch `mobile` — seluruh kode Web & REST API ada di branch `main` (`apps/server/`).
3. Sebelum mengubah model atau panggilan endpoint di `lib/services/api_service.dart`, pastikan kontrak endpoint di branch `main` (`apps/server/routes/api.php` dan `docs/API_CONTRACT.md`) sudah sesuai.
4. Jalankan `flutter analyze` dan `flutter test` sebelum commit/push.
5. Gunakan Conventional Commits (`feat(mobile): ...`, `fix(mobile): ...`, `docs(mobile): ...`).
