# design.md — TugasScroll

Versi 1.0. Pasangan dari PRD v2.0. File ini adalah sumber kebenaran visual dan interaksi. Developer dan coding assistant mengikutinya saat membangun UI Flutter. Kalau ada keputusan desain baru, ubah file ini dulu.

## 1. Arah desain

**Konsep: Halaman.** Feed vertikal tetap ada, tapi rasanya seperti membalik halaman buku tulis, bukan menonton video. Setiap kartu adalah satu halaman dengan garis margin, kertas kotak-kotak atau bergaris, tanda stabilo, dan coretan pulpen koreksi. Elemen-elemen ini diambil dari benda yang memang dipakai pelajar SMA setiap hari: buku tulis, stabilo, pulpen merah guru, dan sampul buku yang berwarna per mapel.

Hal yang dipertahankan dari TikTok hanya mekanismenya: satu kartu satu layar, swipe vertikal, aksi di jangkauan jempol. Rasa, warna, dan ritmenya sengaja berbeda: berujung (ada akhir sesi), tenang, dan tidak mengejar waktu layar.

Prinsip:

1. **Satu halaman, satu pikiran.** Satu soal atau satu konsep per kartu. Kalau isinya panjang, pecah jadi kartu lain atau pindahkan ke panel Dalami.
2. **Feed berujung.** Sesi 10, 20, atau 30 kartu, lalu ada layar selesai. Tidak ada putar otomatis tanpa batas.
3. **Konteks tidak hilang.** Setiap kartu selalu menunjukkan dari tugas dan mapel mana ia berasal.
4. **Warna adalah informasi.** Satu aksen (stabilo), warna status (benar, salah), dan warna sampul mapel. Tidak ada warna dekoratif lain.
5. **Nyaman dipakai malam hari.** Default gelap, tapi bukan hitam pekat dan tidak neon.
6. **Tidak menjebak.** Setiap gestur punya tombol alternatif. Keluar dari sesi selalu satu ketukan.

## 2. Referensi: yang diambil dan yang dibuang

| Referensi | Yang diambil | Yang tidak diambil |
|---|---|---|
| Gambar redesign TikTok dari kamu | Kartu penuh layar, tombol tengah di bar bawah, grid kartu sebagai halaman jelajah | Gradien ungu-biru, bar bawah kaca (blur), cahaya neon di tombol tengah, kolom pencarian, hitungan like dan pengikut, hashtag dan info suara, profil sosial, tombol Follow |
| ScrollEd (feed belajar dari PDF/buku, rencana rilis konsumen Oktober 2026) | Swipe atas untuk topik berikutnya, swipe samping untuk lebih dalam. Sikap sengaja tidak memaksimalkan waktu layar | Video AI sebagai format utama. Laporan tentang app ini juga mencatat risiko konteks hilang kalau swipe langsung mengganti topik, jadi kita jaga konteks per tugas |
| Studii (micro-lesson ala TikTok) | Dua suasana belajar, cepat dan tenang | Mode bergaya "brainrot". Kita hanya memakai versi tenang |
| Knowunity (app belajar SMA dengan scanner PR) | Scanner yang cepat, penjelasan langkah demi langkah, mode gelap dengan aksen cerah, prinsip "jangan menjebak siswa" | Onboarding 30 langkah, paywall di awal, komunitas sosial di MVP. Studi kasus lain menyebut terlalu banyak fitur bisa membingungkan, jadi kita batasi |
| Pola flashcard swipe (gaya Anki dan Quizlet) | Ketuk untuk membuka jawaban, penilaian instan, tombol sebagai alternatif swipe | Meniru merek atau isi kartu aplikasi lain |
| Material dark theme | Permukaan abu gelap (bukan hitam murni), aksen yang tidak terlalu jenuh, kontras minimal AA | Tema Material bawaan apa adanya |
| Benda nyata | Buku tulis folio, garis margin, kertas kotak-kotak, stabilo, pulpen merah guru, sampul per mapel | Tekstur kertas foto-realistis yang berat |

Catatan batas: informasi tentang ScrollEd, Studii, dan Knowunity berasal dari artikel dan halaman toko, bukan dari mencoba langsung aplikasinya. Sebelum mengunci keputusan, coba sendiri minimal dua aplikasi itu.

## 3. Warna

Dua tema: **Malam** (default) dan **Siang**. Pengguna bisa memilih Malam, Siang, atau ikut sistem. Rasio kontras di bawah sudah dihitung.

### 3.1 Tema Malam

| Token | Nama | Hex | Dipakai untuk | Kontras |
|---|---|---|---|---|
| `bg` | Tinta malam | `#12172A` | Latar layar | teks kapur 15,4:1 |
| `page` | Halaman | `#1B2338` | Permukaan kartu | teks kapur 13,6:1 |
| `raised` | Halaman terangkat | `#252F4A` | Sheet, chip, mini player | teks kapur 11,5:1 |
| `ink` | Kapur | `#ECEFF6` | Teks utama | |
| `pencil` | Pensil | `#A3ADC4` | Teks sekunder | 6,9:1 di `page`, 5,9:1 di `raised` |
| `stabilo` | Stabilo | `#F5D547` | Aksen: tombol utama, penanda penting | teks `bg` di atasnya 12,3:1 |
| `pen-red` | Pulpen koreksi | `#FF8A8A` | Salah, langkah keliru | 6,9:1 di `page` |
| `pen-green` | Centang | `#6FD3A0` | Benar | 8,6:1 di `page` |
| `pen-blue` | Pulpen biru | `#8FB2FF` | Tautan, fokus | 7,4:1 di `page` |
| `line` | Garis | `#ECEFF6` pada 10% | Border tipis | |

Tanda stabilo di atas teks memakai `stabilo` pada opasitas 25%. Teks kapur di atasnya tetap 7,1:1.

### 3.2 Tema Siang

| Token | Nama | Hex | Dipakai untuk | Kontras |
|---|---|---|---|---|
| `bg` | Meja | `#F6F8FC` | Latar layar | |
| `page` | Folio | `#FFFFFF` | Permukaan kartu | |
| `raised` | Halaman terangkat | `#EAF0FB` | Sheet, chip | |
| `ink` | Tinta | `#14203D` | Teks utama | 16,1:1 di `page` |
| `pencil` | Pensil | `#4F5B78` | Teks sekunder | 6,8:1 di `page` |
| `primary` | Biru pulpen | `#2347C8` | Tombol utama | teks putih 7,5:1 |
| `stabilo` | Stabilo | `#FFE066` | Penanda penting (opasitas 70%) | teks `ink` 13,3:1 |
| `pen-red` | Pulpen koreksi | `#C62F3A` | Salah | 5,4:1 |
| `pen-green` | Centang | `#1E7A4D` | Benar | 5,3:1 |
| `line` | Garis rapi | `#CFDAF0` | Garis kertas, border | |

### 3.3 Sampul mapel

Warna sampul hanya penanda: garis tepi kartu, titik di chip, sampul di Arsip. Warna ini tidak dipakai untuk teks atau status. Semua nilainya lolos 3:1 sebagai elemen grafis di tema masing-masing.

| Mapel | Malam | Siang |
|---|---|---|
| Matematika | `#8FB2FF` | `#3F63D8` |
| Fisika | `#5CC8E0` | `#0E7F99` |
| Kimia | `#B7A1FF` | `#7B58D6` |
| Biologi | `#8FD27A` | `#4A8F2D` |
| Rumpun IPS (Sejarah, Geografi, Ekonomi, Sosiologi) | `#FFA866` | `#C9661A` |
| Bahasa (Indonesia, Inggris) | `#FF9EC0` | `#C2386F` |
| Pendidikan Agama | `#5ED3B7` | `#12806C` |
| Lainnya dan Umum | `#A3ADC4` | `#66708A` |

Mapel buatan pengguna memilih salah satu warna di atas. Mapel dalam satu rumpun dibedakan lewat nama dan ikon, bukan warna.

Aturan: benar atau salah tidak pernah ditunjukkan hanya dengan warna. Selalu ada ikon dan teks.

## 4. Tipografi

Dua keluarga huruf, dibundel sebagai aset (app offline-first, jangan mengunduh font saat runtime). Cek lisensi OFL saat membundel.

| Peran | Font | Alasan |
|---|---|---|
| UI dan navigasi | Plus Jakarta Sans | Dirancang di Indonesia, terbaca jelas di layar kecil, bentuknya hangat tanpa terlihat main-main |
| Isi halaman (soal, jawaban, pembahasan, catatan) | Literata | Dirancang untuk membaca panjang di layar, memberi rasa buku pada isi kartu |
| Teks Arab (Pendidikan Agama) | Noto Naskh Arabic | Mendukung harakat dan tampil benar kanan-ke-kiri |
| Rumus | Font bawaan flutter_math_fork | Konsisten dengan render LaTeX |

Skala (sp). Ukuran minimum 12 sp, isi kartu minimal 17 sp.

| Gaya | Font | Ukuran / tinggi baris | Berat |
|---|---|---|---|
| Judul layar | Plus Jakarta Sans | 24 / 30 | 700 |
| Judul bagian | Plus Jakarta Sans | 18 / 24 | 600 |
| Soal di kartu | Literata | 21 / 32 | 500 |
| Jawaban dan pembahasan | Literata | 18 / 29 | 400 |
| Isi catatan | Literata | 17 / 27 | 400 |
| Label tombol dan chip | Plus Jakarta Sans | 15 / 20 | 600 |
| Keterangan | Plus Jakarta Sans | 13 / 18 | 500 |
| Teks Arab di kartu | Noto Naskh Arabic | 24 / 42 | 400 |

Aturan: huruf kecil biasa (sentence case) untuk semua label. Tidak ada huruf kapital semua. Spasi huruf normal. Lebar baris isi kartu sekitar 40 sampai 55 karakter, sudah tercapai oleh lebar HP.

## 5. Bentuk, spasi, kedalaman

- **Spasi:** kelipatan 4. Pakai 4, 8, 12, 16, 24, 32, 48. Margin layar 20 dp. Isi kartu mulai 32 dp dari tepi kiri (setelah garis margin).
- **Radius mengikuti peran, bukan satu angka untuk semua:** kartu halaman 10 dp (seperti sudut kertas), chip 6 dp, tombol 12 dp, sheet bawah 20 dp di sudut atas, sampul mapel 6 dp di sisi kanan dan 2 dp di sisi punggung buku.
- **Tanpa bayangan blur.** Kedalaman dibuat dengan tumpukan halaman: dua lembar di belakang kartu aktif, bergeser 4 dp dan 8 dp, warna `raised` dan `page` yang makin pudar. Border tipis `line` 1 dp.
- **Latar kartu:** kertas kotak-kotak (garis 24 dp, opasitas sangat rendah, sekitar 6%) untuk mapel hitungan. Kertas bergaris untuk Catatan dan mapel bahasa. Polos untuk sisanya. Garis kertas tidak boleh mengganggu keterbacaan, uji di layar dengan kecerahan rendah.
- **Garis margin:** satu garis vertikal 2 dp di 24 dp dari kiri, warna sampul mapel pada 70%. Garis ini yang membuat kartu terasa seperti halaman folio.

## 6. Ikon

Satu set saja, bobot reguler, ujung membulat: Phosphor (paket `phosphor_flutter`). Ukuran 24 dp, area ketuk 48 dp. Tidak ada emoji sebagai ikon fungsi. Penanda AI adalah ikon pulpen ditambah teks "Dikoreksi AI", bukan ikon kilau atau bintang.

## 7. Layar

### 7.1 Feed Belajar (layar utama)

```
┌────────────────────────────────────┐
│ Matematika  Fisika  Kimia  Campuran │  tab mapel, bisa digeser
│ ▔▔▔▔▔▔▔▔▔▔                          │  garis bawah = stabilo
│ Soal 7 dari 20, tugas Turunan       │  konteks: urutan dan asal tugas
│                                     │
│ ┃  Turunan dari                     │
│ ┃  f(x) = 3x² + 2x                  │  isi halaman, Literata
│ ┃                                   │
│ ┃  Ketuk untuk lihat jawaban        │
│ ┃                                   │
│ ┃                          Catatan  │  dua aksi samping saja
│ ┃                          Tandai   │
│                                     │
│  Lupa     Susah     Oke     Mudah   │  penilaian, muncul setelah jawaban
│  Besok    2 hari    4 hari  9 hari  │  jarak ulang ditampilkan
│  Lo-fi malam                  ||    │  mini player
│ Arsip     Scan     Belajar  Catatan │  navigasi bawah
└────────────────────────────────────┘
```

- Aksi samping hanya dua (Catatan, Tandai). Tidak ada rel lima ikon, tidak ada tombol like.
- Penilaian Lupa, Susah, Oke, Mudah berada di zona jempol dan baru aktif setelah jawaban dibuka.
- Kartu kesalahan memakai coretan pulpen koreksi: garis bergelombang di bawah langkah yang keliru, catatan margin berwarna `pen-red` seperti "Langkah 3: tanda berubah", plus ikon silang. Langkah yang benar tampil di bawahnya dengan ikon centang.
- Panel **Dalami** dibuka dengan swipe ke kiri: langkah penyelesaian lengkap, foto asli tugas, dan catatan terkait.

### 7.2 Arsip (rak buku)

```
┌────────────────────────────────────┐
│ Arsip                         Cari  │
│ 12 kartu perlu diulang hari ini     │
│                                     │
│ ┌──────────────┐ ┌──────────────┐   │
│ │▌ Matematika  │ │▌ Fisika      │   │  sampul: punggung berwarna
│ │  18 tugas    │ │  7 tugas     │   │
│ │  5 diulang   │ │  0 diulang   │   │
│ └──────────────┘ └──────────────┘   │
│ ┌──────────────┐ ┌──────────────┐   │
│ │▌ Sejarah     │ │▌ Umum        │   │
│ └──────────────┘ └──────────────┘   │
│ Arsip     Scan     Belajar  Catatan │
└────────────────────────────────────┘
```

Arsip adalah rak sampul mapel, bukan grid video. Mapel yang belum punya tugas tidak ditampilkan. Ketuk sampul untuk melihat daftar tugas mapel itu. Tab Perlu dicek muncul hanya bila ada tugas yang menunggu konfirmasi.

### 7.3 Scan dan Cek Hasil

```
┌────────────────────────────────────┐
│ Cek hasil scan             Simpan   │
│ ┌────────────────────────────────┐ │
│ │  foto halaman (bisa dilipat)   │ │
│ └────────────────────────────────┘ │
│ Soal 1                              │
│ Turunan dari f(x) = 3x² + 2x ...    │  bisa diedit
│ Jawabanmu                           │
│ f'(x) = 6x + 2                      │
│ Soal 2                              │
│ Tentukan nilai ░░░░ saat x = 2      │  bagian ragu: stabilo + garis putus
│ ...                                 │
└────────────────────────────────────┘
```

- Bagian yang diragukan AI diberi tanda stabilo agar dicek lebih dulu.
- Tombol shutter di layar kamera berupa cincin tebal polos berwarna kapur. Tidak ada cahaya neon.
- Tombol Scan di bar bawah sedikit lebih besar dari tab lain dan berwarna `stabilo`. Ini satu-satunya elemen yang diberi bobot visual lebih.

## 8. Komponen kunci

| Komponen | Spesifikasi |
|---|---|
| `PageCard` | Satu kartu feed. Latar `page`, margin kiri 32 dp, garis margin sampul, dua lembar di belakang. Isi yang terlalu panjang boleh digulir di dalam kartu (lihat bagian 12) |
| `GradeBar` | Empat tombol sama lebar, tinggi minimal 52 dp, label teks dan jarak ulang di bawahnya. Label: Lupa, Susah, Oke, Mudah. Tidak aktif sebelum jawaban dibuka |
| `StabiloMark` | Sapuan stabilo di bawah atau belakang teks, 25% di Malam dan 70% di Siang. Dipakai untuk penanda penting dan bagian ragu hasil scan |
| `SubjectCover` | Sampul mapel: punggung 8 dp berwarna, nama, jumlah tugas, jumlah kartu perlu diulang |
| `SubjectChip` | Titik warna sampul 8 dp, nama mapel, latar `raised` |
| `VerdictTag` | Ikon centang atau silang atau tanda tanya, teks Benar, Salah, Sebagian, Belum yakin, dan keterangan Dikoreksi AI. Bisa ditimpa pengguna |
| `MiniPlayer` | Pil setinggi 40 dp di atas navigasi bawah: nama track, putar atau jeda. Ketuk untuk membuka sheet playlist |
| `EmptyState` | Satu kalimat konkret dan satu tombol aksi. Tanpa ilustrasi besar |
| `SessionEnd` | Ringkasan sesi (jumlah kartu, berapa yang Lupa), lalu dua pilihan: Lanjut 10 kartu, atau Selesai |

## 9. Gestur dan gerak

| Aksi | Gestur | Alternatif tombol |
|---|---|---|
| Kartu berikutnya | Swipe atas | Tombol Berikutnya (di pengaturan aksesibilitas, bisa dinyalakan) |
| Kartu sebelumnya | Swipe bawah | Tombol Sebelumnya |
| Buka panel Dalami | Swipe kiri | Tombol Dalami di kartu |
| Buka jawaban | Ketuk kartu | Tombol Lihat jawaban |
| Tandai penting | Tekan lama | Tombol Tandai |
| Ganti mapel | Ketuk tab atau swipe di tab | Ketuk tab |

Double tap tidak dipakai. Tidak ada gestur yang hanya bisa dilakukan satu cara.

**Gerak.** Hanya satu momen khas: sapuan stabilo (sekitar 350 ms) saat menandai penting. Sisanya fungsional: pindah kartu 280 ms dengan kurva ease-out, sheet naik 240 ms, penilaian mengubah tombol sekitar 120 ms. Tidak ada animasi masuk fade-dan-geser di setiap daftar, tidak ada konfeti. Hormati pengaturan sistem "kurangi animasi": ganti dengan fade 120 ms. Umpan haptik ringan hanya saat memberi nilai.

## 10. Musik

- Mini player melayang di atas navigasi bawah, bisa disembunyikan.
- Sheet musik bergaya pemilih audio Instagram:
  - Drag handle di atas + kolom pencarian bulat (`Cari...`).
  - Empat pill tab filter horizontal (`Untuk kamu`, `Per mapel`, `Tersimpan`, `File HP`), dengan tab aktif berwarna kontras terang (`ink` dengan teks `bg`).
  - Daftar track vertikal: thumbnail kotak kecil 48×48 dp (radius 8 dp) di kiri, judul track (tebal) + subjudul `artis/suasana • durasi (m:ss)` di tengah, dan tombol ikon Bookmark (`Tersimpan`) di kanan.
  - Kontrol tambahan yang ringkas: volume, pengatur waktu tidur (sleep timer), dan tombol tambah file audio dari HP pada tab `File HP`.
- Volume turun otomatis saat ada notifikasi atau telepon (ducking). Musik berhenti sendiri saat sesi berakhir bila pengatur waktu aktif.
- Sumber: file milik pengguna, track bawaan, dan katalog streaming lo-fi/ambient bebas royalti (CC0). Tampilkan nama sumber dan lisensi track bawaan di halaman Tentang.

## 11. Bahasa antarmuka

Bahasa Indonesia, sapaan "kamu", nada tenang dan langsung, seperti kakak kelas yang membantu. Huruf kecil biasa. Tombol memakai kata kerja yang menyebut apa yang terjadi. Nama aksi sama di seluruh alur: tombol "Simpan" menghasilkan pesan "Tersimpan".

| Situasi | Teks |
|---|---|
| Tombol utama | Scan tugas, Simpan, Mulai belajar, Lihat jawaban, Lanjut 10 kartu |
| Arsip kosong | Belum ada tugas. Foto satu lembar tugasmu untuk mulai. |
| Foto gagal terbaca | Foto terlalu gelap. Dekatkan ke lampu, lalu foto lagi. |
| Tidak ada internet saat scan | Foto sudah tersimpan. Akan dibaca saat kamu online. |
| AI belum yakin | Belum yakin jawabannya benar. Cek langkahmu, atau tandai benar jika gurumu sudah menilainya. |
| Tidak ada kartu jatuh tempo | Semua kartu hari ini sudah diulang. |
| Istirahat setelah 20 kartu | Sudah 20 kartu. Istirahat sebentar, atau lanjut. |

Hindari: "Tingkatkan belajarmu dengan AI", "Ayo semangat!" di setiap layar, pesan rasa bersalah ("Streakmu hilang!"), permintaan maaf berlebihan di pesan error, dan tanda panah di teks tombol.

## 12. Aksesibilitas

- Kontras teks minimal 4,5:1, elemen grafis minimal 3:1 (tabel warna sudah memenuhi).
- Area ketuk minimal 48 dp. Jarak antar tombol penilaian minimal 8 dp.
- Layout tidak boleh pecah pada skala font sistem sampai 200%. Bila isi kartu melebihi layar, isi itu bisa digulir di dalam kartu dan pindah kartu baru terjadi saat gulir sudah di ujung atas atau bawah. Pecah isi panjang menjadi kartu lain bila memungkinkan.
- Benar dan salah selalu ada ikon dan teks, tidak hanya warna.
- Dukung TalkBack dengan urutan baca: konteks, isi kartu, aksi. Semua gestur punya tombol alternatif.
- Hormati "kurangi animasi" dari sistem.
- Teks Latin dan Arab (kanan-ke-kiri) harus tampil benar bersama dalam satu kartu.
- Opsi font ramah disleksia di Pengaturan, misalnya Atkinson Hyperlegible, menggantikan Literata dan Plus Jakarta Sans.

Untuk pengguna remaja: tidak ada profil publik, like, atau papan peringkat di MVP. Notifikasi maksimal satu per hari secara default dengan jam tenang. Tidak ada tekanan lewat copy atau tampilan.

## 13. Daftar anti-"AI slop"

Cek daftar ini setiap kali menambah layar. Semua poin harus terjawab "tidak".

- Apakah ada gradien ungu-biru sebagai latar, header, atau teks?
- Apakah ada efek kaca (blur) di bar bawah atau kartu?
- Apakah ada cahaya atau glow neon di tombol?
- Apakah ada ikon kilau, bintang, atau tongkat ajaib untuk fitur AI?
- Apakah semua kartu memakai radius dan bayangan yang sama tanpa melihat perannya?
- Apakah ada label huruf kapital semua, label kecil di atas judul (eyebrow), atau teks meta berderet dengan titik tengah?
- Apakah ada nomor 01, 02, 03 untuk konten yang bukan urutan langkah? (Langkah penyelesaian soal boleh bernomor.)
- Apakah ada emoji sebagai ikon, atau maskot generik?
- Apakah lebih dari satu warna aksen dipakai untuk hiasan?
- Apakah daftar dan layar memakai animasi fade-geser yang sama di mana-mana?
- Apakah teks UI terdengar seperti iklan, bukan petunjuk?

Uji akhir: tutup logo dan nama app. Kalau layar itu bisa ditukar ke aplikasi lain tanpa terasa janggal, desainnya belum cukup spesifik.

## 14. Catatan implementasi Flutter

- Simpan token di `ThemeExtension` bernama `TsPalette`, satu instance per tema. Jangan hardcode hex di widget.
- Font dan ikon dibundel di `assets/`, daftar di `pubspec.yaml`. Gunakan `package:flutter_math_fork` untuk rumus.
- Feed memakai `PageView` vertikal. Untuk isi kartu yang bisa digulir, gunakan `NestedScrollView` atau `ScrollNotification` agar pindah kartu hanya terjadi di ujung gulir.
- Latar kertas kotak-kotak dan garis dibuat dengan `CustomPainter` agar ringan dan tidak butuh aset gambar.
- Tombol penilaian dan semua gestur punya `Semantics` dan label.
- Uji visual di tiga kondisi: kecerahan rendah, skala font 150% dan 200%, dan layar kecil (360 dp lebar).

Contoh token minimal:

```dart
@immutable
class TsPalette extends ThemeExtension<TsPalette> {
  const TsPalette({
    required this.bg, required this.page, required this.raised,
    required this.ink, required this.pencil, required this.stabilo,
    required this.penRed, required this.penGreen, required this.penBlue,
  });
  final Color bg, page, raised, ink, pencil, stabilo, penRed, penGreen, penBlue;

  static const malam = TsPalette(
    bg: Color(0xFF12172A), page: Color(0xFF1B2338), raised: Color(0xFF252F4A),
    ink: Color(0xFFECEFF6), pencil: Color(0xFFA3ADC4), stabilo: Color(0xFFF5D547),
    penRed: Color(0xFFFF8A8A), penGreen: Color(0xFF6FD3A0), penBlue: Color(0xFF8FB2FF),
  );

  static const siang = TsPalette(
    bg: Color(0xFFF6F8FC), page: Color(0xFFFFFFFF), raised: Color(0xFFEAF0FB),
    ink: Color(0xFF14203D), pencil: Color(0xFF4F5B78), stabilo: Color(0xFFFFE066),
    penRed: Color(0xFFC62F3A), penGreen: Color(0xFF1E7A4D), penBlue: Color(0xFF2347C8),
  );

  // copyWith dan lerp wajib diimplementasikan oleh ThemeExtension.
}
```

## 15. Pertanyaan terbuka

1. Tema default Malam (usulan) atau ikut pengaturan sistem?
2. Nama app dan logo belum ada. Sementara memakai wordmark teks "TugasScroll" dalam Plus Jakarta Sans 700.
3. Maskot: usulan tidak ada. Setuju?
4. Bagian lain dari gambar referensi yang ingin dipertahankan, selain yang sudah tercantum di bagian 2?
5. Font: setuju memakai Plus Jakarta Sans dan Literata, atau ada font yang kamu sukai?

## 16. Sumber

- ScrollEd: https://runtimewire.com/article/scrolled-turns-textbooks-into-swipeable-learning-feed dan https://propakistani.pk/2026/09/21/this-app-turns-your-study-material-into-a-tiktok-style-learning-feed/
- Studii: https://apps.apple.com/ca/app/studii-doomscroll-learn/id6755154363
- SwipeNStudy: https://www.capterra.in/software/1103631/SwipeNStudy
- Knowunity: https://screensdesign.com/showcase/knowunity-ai-study-homework dan https://contra.com/p/L2bmmAbv-knowunity-designing-for-a-voice-powered-active-recall
- Pola flashcard swipe: https://vp0.com/blogs/flashcard-swipe-ui-like-anki-quizlet
- Material dark theme: https://m2.material.io/design/color/dark-theme
