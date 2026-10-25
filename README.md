# TugasScroll

Aplikasi Flutter **offline-first** untuk belajar ulang dari tugas sekolah yang sudah selesai dengan konsep visual **"Halaman Buku Tulis"** (pasangan [prd.md](file:///root/prd.md) v2.0 dan [design.md](file:///root/design.md) v1.0).

## Cara Menjalankan Proyek

1. Pastikan Flutter SDK (`>=3.19.0`) sudah terpasang.
2. Buat folder platform Android jika baru pertama kali *clone*:
   ```bash
   flutter create --platforms=android --org id.tugasscroll .
   ```
3. Unduh file font berlisensi OFL ke `assets/fonts/`:
   - `PlusJakartaSans-Medium.ttf`, `PlusJakartaSans-SemiBold.ttf`, `PlusJakartaSans-Bold.ttf`
   - `Literata-Regular.ttf`, `Literata-Medium.ttf`
   - `NotoNaskhArabic-Regular.ttf`
   - `AtkinsonHyperlegible-Regular.ttf`, `AtkinsonHyperlegible-Bold.ttf`
4. Jalankan dependensi dan aplikasi:
   ```bash
   flutter pub get
   flutter test
   flutter run
   ```
