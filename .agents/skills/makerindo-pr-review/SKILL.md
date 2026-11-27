---
name: makerindo-pr-review
description: >-
  Gunakan saat meninjau atau mempromosikan Pull Request pada track mobile (staging-mobile atau mobile).
---

# Makerindo PR Review Skill (Mobile)

## 1. Konteks Branch Target
- **`staging-mobile`:** PR fitur, bugfix, docs, atau chore dari branch kerja (`feat/*`, `fix/*`, dll.).
- **`mobile`:** Promotion PR dari `staging-mobile` (atau `hotfix/*` darurat) setelah QC selesai.
- Tolak setiap PR yang mencoba menggabungkan branch `main` / `staging-main` ke track mobile.

## 2. Checklist Review
1. **Keamanan & Signing:** Tidak ada `.env*`, `.jks`, `.keystore`, `key.properties`, `google-services.json`, atau token nyata di diff.
2. **Kontrak API:** Perubahan model/endpoint di `lib/models/models.dart` dan `lib/services/api_service.dart` kompatibel dengan branch `main`.
3. **Kualitas Kode & Tests:** `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, dan `flutter test` lulus.
4. **Workflow & Kebersihan:** Judul PR Conventional Commits, tanpa atribusi AI, serta check `CI Gate`, `PR Policy`, dan `Security` lulus.
