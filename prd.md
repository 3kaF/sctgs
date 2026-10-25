# PRD – Aplikasi Belajar Scroll (Flutter)

Nama sementara: **TugasScroll** · Platform: Android dulu (iOS menyusul) · Versi dokumen: 2.0

## 1. Ringkasan

TugasScroll adalah aplikasi Flutter untuk belajar ulang dari tugas yang sudah selesai. Pengguna memotret lembar tugas atau halaman buku berisi soal dan jawaban yang sudah dikerjakan. AI membaca fotonya, mengelompokkannya per mata pelajaran (Matematika, Fisika, Kimia, Biologi, bahasa, sejarah, agama, dan mapel lain), memeriksa jawaban, lalu mengubahnya menjadi kartu belajar di feed vertikal ala TikTok, lengkap dengan musik latar dan catatan.

**Ide inti:** tugas yang sudah dikumpulkan tidak berhenti di buku; ia menjadi bahan review yang muncul lagi tepat sebelum terlupa.

## 2. Masalah & Target Pengguna

**Masalah**

- Tugas sudah selesai dan dikumpulkan, lalu isinya terlupa saat ujian.
- Mengulang lewat buku atau galeri foto membosankan dan tidak terstruktur.
- Kesalahan di tugas jarang dipelajari lagi.
- Foto tugas menumpuk di galeri tanpa pengelompokan per mapel.

**Target pengguna utama:** pelajar SMA/SMK dan mahasiswa tahun awal, 15–22 tahun, terbiasa dengan TikTok/Reels, dengan cakupan semua mata pelajaran sekolah sejak awal.

**Persona singkat**

- **Rani (16, SMA kelas 11 IPA):** punya tumpukan tugas dari banyak mapel (Matematika, Kimia, Sejarah, dan lainnya) yang sudah dinilai; ingin mengulangnya sebelum ulangan harian, di sela waktu pakai HP.
- **Dimas (19, mahasiswa TPB):** mengerjakan banyak soal latihan; ingin mengulang yang salah sebelum kuis.

## 3. Tujuan & Metrik Sukses

| Tujuan | Metrik | Target 3 bulan setelah rilis |
| --- | --- | --- |
| Dipakai rutin | Retensi hari ke-7 | ≥ 25% |
| Tugas masuk ke app | Tugas yang di-scan per pengguna aktif per minggu | ≥ 3 |
| Scan akurat | Hasil scan yang diedit berat oleh pengguna | ≤ 20% |
| Review berjalan | Kartu yang direview per sesi | ≥ 15 |
| Belajar efektif | Kartu sulit yang dijawab benar pada review ke-3 | ≥ 60% |
| AI bisa dipercaya | Akurasi klasifikasi mapel; akurasi koreksi jawaban hitungan | ≥ 90%; ≥ 90% |
| Stabil | Sesi tanpa crash | ≥ 99% |

## 4. Ruang Lingkup

**MVP (wajib ada saat rilis pertama)**

1. Scan foto tugas (kamera atau galeri), potong otomatis, multi-halaman; input ketik/paste sebagai cadangan.
2. AI membaca teks, tulisan tangan, dan rumus, dengan layar Cek Hasil yang bisa diedit.
3. AI menyortir per mapel dan topik, memeriksa jawaban, dan menandai yang perlu dicek.
4. Arsip tugas selesai per mapel untuk semua mapel sekolah (daftar bawaan + mapel buatan sendiri).
5. Kartu AI dari soal dan jawaban pengguna, termasuk kartu kesalahan.
6. Feed scroll vertikal: satu feed per mapel dan feed Campuran.
7. Review otomatis (pengulangan berjarak) dan pengingat harian untuk kartu yang jatuh tempo.
8. Catatan pribadi per kartu atau tugas.
9. Musik latar (file milik pengguna + track bebas royalti).
10. Mode offline untuk arsip, kartu, dan review.

**Setelah MVP (v1.1+)**

- Akun dan sinkronisasi antar perangkat, cadangan foto ke cloud.
- Mapel khusus (mis. mapel kuliah, bahasa asing lain, bahasa daerah).
- Streak, widget, statistik lanjutan.
- Berbagi kartu buatan sendiri ke teman.
- iOS.

**Di luar cakupan (sementara)**

- Mengatur tugas yang belum selesai (deadline, prioritas, to-do).
- Streaming musik dari Spotify/YouTube (risiko hak cipta dan lisensi).
- Membagikan foto halaman buku ke publik.

## 5. User Stories (ringkas)

- Sebagai pelajar, saya memotret PR Matematika yang sudah dinilai dan app langsung memisahkannya per soal.
- Saya ingin mengecek hasil bacaan AI dan memperbaikinya sebelum disimpan, karena tulisan tangan saya kadang terbaca salah.
- Saya ingin tahu bila jawaban saya salah dan di langkah mana.
- Saya ingin tugas dari semua mapel terkumpul rapi di daftar masing-masing.
- Saya ingin memilih feed satu mapel saja (mis. Kimia) saat fokus, atau Campuran saat santai.
- Saya ingin kartu yang saya lupa muncul lagi lebih cepat, tanpa mengatur jadwal sendiri.
- Saya ingin menulis catatan di kartu yang sulit, dengan musik yang tetap jalan saat scroll.
- Saya ingin menolak koreksi AI bila guru sudah menyatakan jawaban saya benar.

## 6. Spesifikasi Fitur

### 6.1 Arsip Tugas Selesai (P0)

- Satu entri = satu soal yang sudah dikerjakan: teks soal, jawaban pengguna, foto asli, mapel, topik, tanggal dikerjakan (default hari ini, bisa diubah), tingkat penguasaan.
- Tidak ada deadline, prioritas, atau status kerja. Yang ada hanya tingkat penguasaan: Baru, Lemah, Cukup, Kuat.
- Daftar per mapel: Semua | tiap mapel yang dipakai | Umum | Perlu dicek; filter topik dan tanggal; pencarian teks.
- Input ketik/paste tetap ada bila foto bermasalah.
- Menghapus tugas menghapus kartu, catatan terkait, dan fotonya (dengan konfirmasi).

### 6.2 Scan Tugas (P0)

Alur: ambil foto atau pilih dari galeri → potong dan luruskan otomatis → tambah halaman (maks 10 foto per sesi scan) → AI membaca → layar Cek Hasil.

- **Cek Hasil:** foto di atas, teks hasil bacaan di bawah, dipisah per soal (teks soal dan jawaban pengguna). Pengguna bisa mengedit, menggabung, memisah, atau menghapus soal. Rumus tampil terrender sebagai pratinjau.
- Satu foto berisi banyak soal → AI memisahkannya menjadi beberapa entri.
- Bagian dengan keyakinan rendah ditandai kuning agar dicek lebih dulu.
- Tulisan tangan dan rumus adalah kasus tersulit, jadi hasil selalu bisa diedit sebelum disimpan.
- Foto asli disimpan di penyimpanan privat app. Foto hanya diunggah ke server untuk diproses AI, lalu dihapus dari server.

### 6.3 Penyortiran & Koreksi AI (P0)

Keluaran per soal: `subject`, `topic`, `difficulty` (1–5), `verdict` (benar, salah, sebagian, tidak yakin), `mistake_step`, `confidence`.

- `confidence` < 0,6 → masuk tab Perlu dicek dan pengguna diminta mengonfirmasi mapel.
- **Koreksi:** AI menyelesaikan soal sendiri lalu membandingkannya dengan jawaban pengguna. Bila tidak yakin, verdict-nya `tidak yakin`, bukan tebakan.
- Pengguna bisa menimpa verdict: “jawaban saya benar menurut guru” atau “memang salah”. Penimpaan menjadi acuan pembuatan kartu dan disimpan untuk memperbaiki prompt.
- Mapel bawaan (usulan): Matematika, Fisika, Kimia, Biologi, Bahasa Indonesia, Bahasa Inggris, Sejarah, Geografi, Ekonomi, Sosiologi, PPKn, Pendidikan Agama, Informatika, Seni, PJOK. Tugas lintas mapel atau yang tidak dikenali masuk Umum. Pengguna bisa menambah mapel sendiri.

**Jenis soal:** hitungan, pilihan ganda, isian, uraian, atau hafalan (disimpan di `question_type`). Untuk soal hitungan, AI memberi verdict tegas. Untuk uraian dan hafalan, AI memberi saran (bagian yang kurang, kelengkapan jawaban), bukan vonis benar atau salah mutlak.

### 6.4 Kartu AI (P0)

Setiap soal menjadi 3–8 kartu:

- **Soal ulang:** soal tampil, jawaban disembunyikan; ketuk untuk melihat.
- **Kartu kesalahan:** hanya bila jawaban salah atau sebagian; menunjukkan langkah yang keliru dan langkah yang benar.
- **Konsep:** rumus atau aturan di balik soal, satu layar.
- **Flashcard:** pasangan istilah–definisi atau rumus.
- **Variasi soal:** soal serupa dengan angka berbeda (hanya untuk soal hitungan: Matematika, Fisika, Kimia).
- **Catatan pengguna:** kartu milik sendiri yang ikut muncul di feed.

Aturan konten per jenis mapel: soal hitungan (Matematika, Fisika, Kimia) memakai render LaTeX; Kimia juga mendukung rumus senyawa (H₂O, subscript/superscript), persamaan reaksi, dan tabel periodik mini. Mapel bahasa memakai kartu kosakata, tata bahasa, dan kutipan teks. Sejarah, Geografi, Biologi, dan Ekonomi memakai kartu istilah, kronologi, dan sebab-akibat. Pendidikan Agama mendukung teks Arab (kanan-ke-kiri) dan hanya memakai ayat, hadis, atau doa yang ada di tugas pengguna; AI tidak mengarang kutipan. Pembahasan baru tampil setelah pengguna mengetuk “lihat jawaban”.

### 6.5 Feed Scroll Vertikal (P0)

- Satu kartu = satu layar penuh, swipe atas/bawah (PageView vertikal), 60 fps.
- Satu feed per mapel plus feed Campuran (semua mapel termasuk Umum); ganti lewat tab atas yang bisa digeser.
- Aksi di sisi kanan ala TikTok: Tandai penting, Catatan, Ulangi nanti, Paham. Setelah jawaban dibuka muncul penilaian Lupa / Susah / Oke / Mudah.
- Urutan feed: kartu jatuh tempo review → kartu dari jawaban salah → kartu baru → review acak. Ada sedikit acak agar tidak monoton.
- Progress tipis di atas layar; sesi 10, 20, atau 30 kartu, lalu ringkasan sesi dan opsi lanjut.
- Bila tidak ada kartu jatuh tempo, app menawarkan kartu baru atau latihan bebas.

### 6.6 Catatan (P0)

- Catatan teks per kartu atau per tugas, dengan format dasar (tebal, daftar) dan simpan otomatis.
- Halaman Semua Catatan dengan pencarian dan filter mapel.
- Catatan yang ditandai tampil sebagai kartu di feed.

### 6.7 Musik (P0 sederhana, P1 lengkap)

- Mini player melayang: putar/jeda, next, volume.
- Sumber P0: file audio dari perangkat + 5–10 track lo-fi/ambient bebas royalti.
- Playlist per mapel (mis. Kimia = ambient, Matematika = lo-fi).
- Audio tetap jalan saat layar mati dan mengecil otomatis (ducking) saat ada notifikasi atau telepon.

### 6.8 Review Otomatis & Statistik (P0 review, P1 statistik)

- Tiap kartu punya jadwal ulang. Setelah menilai Lupa / Susah / Oke / Mudah, jarak ke review berikutnya dihitung dengan aturan mirip SM-2: naik bila mudah, kembali pendek bila lupa. Kartu dari jawaban salah mulai dengan jarak 1 hari.
- Pengingat harian (notifikasi lokal) di jam pilihan pengguna: “12 kartu perlu diulang”. Hanya muncul bila ada kartu jatuh tempo, maksimal satu per hari secara default, dengan jam tenang.
- Statistik: kartu dikuasai, mapel dan topik terlemah, topik yang paling sering salah, streak harian.

### 6.9 Akun & Sinkronisasi (P1, v1.1)

- Login Google/email; data lokal tetap sumber utama (offline-first), sinkronisasi berjalan di latar.
- Cadangan foto ke cloud bersifat opsional dan harus diaktifkan pengguna.

## 7. Alur Layar (Information Architecture)

1. **Onboarding** (3 layar): pilih jenjang, pilih mapel, izin kamera dan notifikasi.
2. **Arsip:** daftar tugas selesai per mapel (tab Semua | tiap mapel | Umum | Perlu dicek), tombol Scan besar.
3. **Scan:** kamera, potong otomatis, tambah halaman.
4. **Cek Hasil:** foto + teks per soal, edit, simpan.
5. **Detail Tugas:** soal, jawaban, verdict AI (bisa ditimpa), daftar kartu, tombol Mulai belajar.
6. **Feed Belajar:** tab per mapel | Campuran, kartu penuh layar, aksi samping, mini player musik.
7. **Catatan:** daftar dan editor.
8. **Musik:** perpustakaan dan playlist.
9. **Statistik** (P1).
10. **Pengaturan:** tema, jam pengingat, data dan privasi, hapus akun.

Navigasi bawah: Arsip · Scan · Belajar (tengah, menonjol) · Catatan · Profil.

## 8. Desain AI

**Pendekatan:** foto dibaca oleh model multimodal (vision) lewat backend ringan, sehingga API key tidak ada di aplikasi. Model vision dipilih sebagai jalur utama karena tulisan tangan dan rumus sulit bagi OCR biasa. OCR on-device (Google ML Kit) disiapkan sebagai cadangan untuk teks cetak dan pratinjau saat offline. Semua keluaran AI dipaksa berformat JSON dan divalidasi skema sebelum disimpan.

**Pipeline**

1. **Pra-proses di perangkat:** potong, luruskan, perkecil (sisi terpanjang ≤ 1600 px), kompres.
2. **`scan_task`:** gambar → daftar soal dan jawaban pengguna (rumus sebagai LaTeX) + keyakinan per bagian.
3. **Cek Hasil:** pengguna memperbaiki hasil bacaan. Tidak ada soal yang diolah lebih lanjut sebelum dikonfirmasi.
4. **`classify_and_grade`:** teks terverifikasi → mapel, topik, kesulitan, verdict.
5. **Verifikasi silang:** Soal hitungan (Matematika, Fisika, Kimia) dihitung ulang dengan library ekspresi; Kimia juga dicek kesetimbangan massa dan muatan dengan aturan sederhana. Mapel non-hitungan tidak punya verifikasi silang. Bila hasilnya beda dari AI, verdict menjadi `tidak yakin`.
6. **`generate_cards`:** kartu dibuat dan disimpan; tidak dibuat ulang kecuali diminta.

**Contoh keluaran `scan_task`**

```json
{
  "items": [
    {
      "question": "Turunan dari f(x) = 3x^2 + 2x adalah ...",
      "user_answer": "f'(x) = 6x + 2",
      "confidence": 0.88,
      "low_confidence_parts": []
    }
  ]
}
```

**Contoh keluaran `classify_and_grade`**

```json
{
  "subject": "matematika",
  "topic": "turunan fungsi",
  "difficulty": 2,
  "verdict": "correct",
  "mistake_step": null,
  "confidence": 0.93
}
```

**Guardrail dan kualitas**

- Hasil bacaan tidak pernah dipercaya tanpa konfirmasi pengguna (layar Cek Hasil).
- AI bisa salah mengoreksi: ada label “dikoreksi AI”, tombol timpa, dan tombol Laporkan kartu salah. Untuk uraian dan hafalan (terutama Pendidikan Agama), keluaran berupa saran, bukan vonis benar atau salah.
- Gambar lebih mahal diproses daripada teks: perkecil gambar, batasi jumlah scan harian untuk akun gratis, cache semua hasil.
- Privasi: sarankan memotong bagian nama/NIS sebelum scan, jangan kirim metadata foto, hapus foto dari server setelah diproses.
- Fallback: bila AI gagal atau offline, foto tetap tersimpan sebagai Belum diproses dan diantre untuk diproses saat online.
- Set uji: 100+ foto tugas nyata (cetak dan tulisan tangan, berbagai pencahayaan) dengan label benar, untuk mengukur tingkat salah baca dan akurasi koreksi setiap kali prompt atau model diganti.

## 9. Arsitektur Teknis

| Lapisan | Pilihan yang disarankan | Alasan |
| --- | --- | --- |
| UI | Flutter 3.x, Material 3 + tema kustom | Satu basis kode, performa baik |
| State | Riverpod | Mudah diuji, skalabel |
| Navigasi | go\_router | Deep link dan struktur jelas |
| Kamera & potong dokumen | camera atau image\_picker + document scanner (mis. google\_mlkit\_document\_scanner atau cunning\_document\_scanner) | Potong dan luruskan otomatis; paket final dipilih di Fase 2 |
| Kompres gambar | flutter\_image\_compress | Hemat kuota dan biaya AI |
| OCR cadangan | google\_mlkit\_text\_recognition | Jalan offline untuk teks cetak |
| Database lokal | Drift (SQLite) | Query relasional, migrasi rapi, offline-first |
| Backend | Supabase (Postgres + Auth + Storage + Edge Functions) | Cepat dibangun, SQL standar, gratis untuk awal |
| AI | API LLM multimodal dipanggil dari Edge Function | Kunci API aman, model bisa diganti |
| Audio | just\_audio + audio\_service + audio\_session | Putar di latar, ducking |
| Render rumus | flutter\_math\_fork (LaTeX) | Matematika dan Kimia tampil rapi |
| Notifikasi | flutter\_local\_notifications | Pengingat review tanpa server |
| Analitik/Crash | Firebase Crashlytics + analitik ringan | Pantau stabilitas |
| CI/CD | GitHub Actions atau Codemagic | Build dan rilis otomatis |

**Struktur proyek (feature-first)**

```
lib/
  core/        # tema, util, error, konstanta
  data/        # drift db, repository, api client, sync
  features/
    archive/  scan/  feed/  cards/  review/  notes/  music/  ai/  stats/  settings/
  app.dart
  main.dart
```

**Prinsip:** offline-first (UI selalu membaca database lokal; sinkronisasi hanya mendorong/menarik perubahan), pemisahan UI–domain–data yang jelas, semua panggilan AI lewat satu `AiService`, dan logika jadwal review di domain layer supaya mudah diuji.

**Catatan lingkungan dev:** Flutter dan emulator Android butuh perangkat yang cukup kuat. Bila mengembangkan dari perangkat terbatas, build bisa dilakukan lewat CI cloud (Codemagic/GitHub Actions) dan diuji di HP fisik lewat APK.

## 10. Desain Database

### 10.1 Skema lokal (SQLite via Drift) dan server (Postgres)

Skema dibuat sama agar sinkronisasi mudah. Semua tabel punya `id` (UUID), `created_at`, `updated_at`, dan `deleted_at` (soft delete) untuk sinkronisasi.

```sql
-- Mapel (bawaan sistem + buatan pengguna)
CREATE TABLE subjects (
  id UUID PRIMARY KEY,
  user_id UUID NULL,            -- NULL = mapel bawaan
  name TEXT NOT NULL,           -- Matematika, Fisika, Kimia, ..., Umum
  color TEXT, icon TEXT,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

-- Satu sesi scan = beberapa foto yang diproses bersama
CREATE TABLE scans (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  status TEXT DEFAULT 'pending',    -- pending | processing | done | failed
  page_count INT,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

CREATE TABLE task_images (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  scan_id UUID REFERENCES scans(id),
  page_no SMALLINT,
  local_path TEXT NOT NULL,         -- penyimpanan privat app
  remote_path TEXT NULL,            -- hanya saat diproses / bila cadangan aktif
  width INT, height INT,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

-- Satu baris = satu soal yang sudah dikerjakan
CREATE TABLE tasks (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  subject_id UUID REFERENCES subjects(id),
  scan_id UUID NULL REFERENCES scans(id),
  title TEXT,                       -- ringkasan singkat soal
  question_text TEXT NOT NULL,      -- teks soal terverifikasi (LaTeX bila ada)
  user_answer_text TEXT,            -- jawaban yang dikerjakan pengguna
  topic TEXT,
  done_on DATE,                     -- tanggal dikerjakan
  question_type TEXT,               -- hitungan | pilihan_ganda | isian | uraian | hafalan
  difficulty SMALLINT,              -- 1..5
  mastery SMALLINT DEFAULT 0,       -- 0 baru, 1 lemah, 2 cukup, 3 kuat
  ai_verdict TEXT,                  -- correct | wrong | partial | unsure
  mistake_step TEXT,
  user_verdict TEXT NULL,           -- timpaan pengguna: correct | wrong
  ai_confidence REAL,
  needs_check BOOLEAN DEFAULT FALSE,
  source TEXT DEFAULT 'scan',       -- scan | manual
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

CREATE TABLE cards (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  task_id UUID REFERENCES tasks(id),
  subject_id UUID REFERENCES subjects(id),
  type TEXT NOT NULL,               -- question | mistake | concept | flashcard | variant | note
  content JSONB NOT NULL,           -- soal/teks (mendukung LaTeX)
  answer JSONB,
  explanation TEXT,
  generated_by TEXT,                -- ai | user
  reported BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

-- Jadwal review per kartu (pengulangan berjarak)
CREATE TABLE card_progress (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  card_id UUID REFERENCES cards(id),
  seen_count INT DEFAULT 0,
  lapses INT DEFAULT 0,             -- berapa kali dinilai Lupa
  last_grade SMALLINT,              -- 0 Lupa, 1 Susah, 2 Oke, 3 Mudah
  ease REAL DEFAULT 2.5,
  interval_days INT DEFAULT 0,
  next_review_at TIMESTAMPTZ,
  last_seen_at TIMESTAMPTZ,
  is_starred BOOLEAN DEFAULT FALSE,
  repeat_later BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ,
  UNIQUE (user_id, card_id)
);

CREATE TABLE notes (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  task_id UUID NULL REFERENCES tasks(id),
  card_id UUID NULL REFERENCES cards(id),
  body TEXT NOT NULL,
  show_in_feed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

CREATE TABLE playlists (
  id UUID PRIMARY KEY, user_id UUID NOT NULL,
  name TEXT NOT NULL, subject_id UUID NULL,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

CREATE TABLE tracks (
  id UUID PRIMARY KEY, user_id UUID NOT NULL,
  playlist_id UUID REFERENCES playlists(id),
  title TEXT, source_type TEXT,     -- bundled | local_file
  uri TEXT NOT NULL, duration_sec INT,
  created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ, deleted_at TIMESTAMPTZ
);

CREATE TABLE study_sessions (
  id UUID PRIMARY KEY, user_id UUID NOT NULL,
  feed_mode TEXT,                   -- math | chem | mixed
  started_at TIMESTAMPTZ, ended_at TIMESTAMPTZ,
  cards_viewed INT, cards_correct INT
);

CREATE TABLE ai_jobs (
  id UUID PRIMARY KEY, user_id UUID NOT NULL,
  type TEXT,                        -- scan | grade | generate_cards
  scan_id UUID NULL, task_id UUID NULL,
  status TEXT,                      -- queued | done | failed
  tokens_used INT, error TEXT,
  created_at TIMESTAMPTZ
);
```

**Indeks penting:** `tasks(user_id, subject_id, done_on)`, `tasks(user_id, needs_check)`, `cards(user_id, subject_id)`, `card_progress(user_id, next_review_at)`, `scans(user_id, status)`; pencarian teks dengan FTS5 (lokal) dan `tsvector` (server).

### 10.2 Keamanan data di server

- Aktifkan **Row Level Security** di semua tabel: pengguna hanya bisa membaca/menulis baris dengan `user_id = auth.uid()`.
- Mapel bawaan (`user_id IS NULL`) hanya bisa dibaca.
- Bucket foto bersifat privat; objek di bucket dihapus segera setelah `scans.status` menjadi `done`, kecuali pengguna mengaktifkan cadangan foto.

### 10.3 Strategi sinkronisasi (v1.1)

- Basis: `updated_at` + soft delete; tarik perubahan sejak `last_sync_at`, dorong perubahan lokal.
- Konflik: *last-write-wins* per baris (cukup untuk satu pengguna dengan beberapa perangkat).
- Foto dan file musik tidak disinkronkan; hanya metadatanya, kecuali cadangan foto diaktifkan.

### 10.4 Migrasi

Setiap perubahan skema = versi migrasi Drift bernomor + skrip SQL server di repositori; wajib diuji dengan data lama sebelum rilis.

## 11. API / Edge Functions

| Endpoint | Fungsi | Catatan |
| --- | --- | --- |
| `POST /ai/scan` | Gambar → soal dan jawaban pengguna | Batas ukuran per gambar, rate limit per pengguna |
| `POST /ai/grade` | Klasifikasi mapel/topik + koreksi jawaban | Hanya menerima teks yang sudah dikonfirmasi pengguna |
| `POST /ai/generate-cards` | Buat kartu dari tugas | Hasil disimpan, idempoten |
| `POST /ai/explain` | Jelaskan ulang kartu yang sulit | Opsional P1 |
| `POST /feedback/card` | Laporkan kartu atau koreksi yang salah | Untuk perbaikan prompt |
| Auth & sync | Disediakan Supabase | v1.1 |

## 12. Kebutuhan Non-Fungsional

- **Performa:** cold start < 2,5 detik di HP kelas menengah; scroll feed stabil 60 fps; kartu berikutnya di-preload; hasil scan satu halaman < 15 detik di jaringan 4G.
- **Offline:** arsip, feed, review, catatan, dan musik berjalan tanpa internet; scan menunggu antrean sampai online.
- **Penyimpanan:** foto dikompres otomatis; pengaturan menampilkan pemakaian penyimpanan dan opsi menghapus foto asli sambil mempertahankan teks dan kartu.
- **Ukuran app:** target < 50 MB (AAB).
- **Aksesibilitas:** ukuran teks bisa diatur, kontras cukup, dukungan TalkBack dasar. Teks Latin dan Arab (kanan-ke-kiri) harus tampil benar di kartu, catatan, dan hasil scan.
- **Bahasa:** Indonesia dulu; siapkan struktur lokalisasi (`intl`) sejak awal.
- **Baterai:** audio latar dan animasi tidak boros; hentikan preload saat baterai rendah.
- **Kompatibilitas:** Android 8.0+ (API 26) sebagai batas awal.

## 13. Keamanan, Privasi, dan Kepatuhan

- Banyak pengguna adalah remaja: kumpulkan data seminimal mungkin, tanpa iklan bertarget, dan pertimbangkan persetujuan orang tua untuk usia di bawah batas hukum setempat.
- **Foto tugas bisa memuat nama, sekolah, atau NIS.** Sarankan memotong bagian itu saat scan, jangan kirim metadata foto (EXIF), dan hapus foto dari server setelah diproses.
- Pilih penyedia AI yang tidak memakai data API untuk melatih model, dan periksa kebijakannya sebelum rilis.
- **Hak cipta:** foto halaman buku paket adalah konten pihak lain. Foto disimpan privat untuk belajar pribadi dan tidak bisa dibagikan publik; fitur berbagi (setelah MVP) hanya untuk kartu buatan pengguna.
- Izin kamera diminta saat pertama kali fitur Scan dipakai, bukan di awal onboarding.
- Kebijakan privasi dan syarat layanan dalam bahasa mudah dipahami; wajib ada sebelum rilis.
- Fitur hapus akun dan hapus semua data (termasuk foto) dari dalam aplikasi.
- Kunci API hanya di server; komunikasi HTTPS; token disimpan dengan `flutter_secure_storage`.
- Musik: hanya track bebas royalti atau file milik pengguna.
- Isi form **Data Safety** di Play Console sesuai data yang benar-benar dikumpulkan, termasuk foto yang dikirim untuk diproses.

## 14. Roadmap Pengembangan (perkiraan pengembang solo)

| Fase | Durasi | Isi | Hasil / Kriteria selesai |
| --- | --- | --- | --- |
| 0. Discovery | 1 minggu | Wawancara 5–10 calon pengguna, kumpulkan 30 foto tugas nyata dari berbagai mapel, finalkan nama dan lingkup MVP | Lingkup MVP disetujui |
| 1. Desain | 1–2 minggu | Wireframe, alur Scan → Cek Hasil → Feed, UI kit, prototipe klik (Figma) | Prototipe diuji ke 5 orang |
| 2. Fondasi teknis | 1–2 minggu | Repo, struktur proyek, tema, Drift + migrasi awal, CI, flavor dev/prod; **uji jalur baca foto**: bandingkan model vision vs ML Kit pada 30 foto | Aplikasi kosong jalan, CI hijau, jalur baca foto dipilih |
| 3. Inti MVP | 3–4 minggu | Arsip tugas, kamera + potong, layar Cek Hasil, feed vertikal, kartu manual, render LaTeX/kimia dan teks Arab (kanan-ke-kiri) | Bisa scan, edit, simpan, dan scroll kartu (tanpa koreksi AI) |
| 4. AI | 3–4 minggu | Edge Function `scan`, `grade`, `generate-cards`, validasi JSON, verifikasi silang hitungan, antrean offline | Salah baca dan akurasi koreksi memenuhi target pada set uji |
| 5. Review, Catatan, Musik | 2–3 minggu | Jadwal pengulangan, pengingat harian, editor catatan, mini player latar | Review berjalan, audio stabil di latar dan saat ada telepon |
| 6. Polish | 1–2 minggu | Onboarding, animasi, tema gelap, empty/error state, penghapusan data | Semua layar punya state lengkap |
| 7. QA & Beta tertutup | 2–3 minggu | Uji unit/widget/integrasi, uji di 5+ perangkat, 20–30 tester, perbaikan bug | Crash-free ≥ 99%, tidak ada bug P0 |
| 8. Rilis | 1 minggu | Aset toko, kebijakan privasi, build rilis, submit review | Live di Play Store (produksi bertahap) |
| 9. Pasca-rilis | berjalan | Pantau metrik, perbaiki bug, v1.1 (akun + sinkronisasi + cadangan foto) | Rilis berkala tiap 2–4 minggu |

Total sampai rilis: sekitar **16–22 minggu**, lebih panjang dari rencana awal karena scan foto dan review otomatis kini masuk MVP. Bila waktu terbatas, geser statistik, musik lengkap, dan akun ke v1.1.

## 15. Strategi Pengujian

- **Unit test:** algoritma jadwal review, urutan feed, parser JSON AI, pemisahan soal hasil scan.
- **Widget test:** kartu (soal ulang, kesalahan, flashcard), layar Cek Hasil, mini player.
- **Integration test:** alur foto → Cek Hasil → simpan → kartu muncul → dinilai → jadwal berubah.
- **Uji baca foto:** 100+ foto nyata dari berbagai mapel (cetak, tulisan tangan rapi dan berantakan, cahaya redup, miring, bayangan); ukur tingkat salah baca karakter dan seberapa sering pengguna harus mengedit.
- **Uji koreksi:** soal hitungan (Matematika, Fisika, Kimia) berkunci jawaban, plus sampel uraian dan hafalan; ukur kesesuaian verdict AI dengan kunci, dan seberapa sering AI menjawab `tidak yakin`.
- **Uji perangkat:** minimal 5 HP (RAM 3–8 GB, Android 8–15), layar kecil dan besar, kamera kelas bawah.
- **Uji performa:** profil di mode profile (DevTools) untuk jank dan memori; uji 1.000 kartu di feed.
- **Uji audio:** telepon masuk, headset dicabut, aplikasi di-swipe dari recent.
- **Beta:** Firebase App Distribution atau Play Internal/Closed Testing, formulir umpan balik di dalam app.

## 16. Rencana Rilis

### 16.1 Persiapan

1. Akun **Google Play Console** (biaya satu kali, sekitar US$25). Akun pribadi baru biasanya wajib menjalankan *closed testing* dengan jumlah penguji minimum selama beberapa hari sebelum bisa ke produksi, jadi cek aturan terbaru dan mulai beta lebih awal.
2. Tentukan `applicationId` final (mis. `id.tugasscroll.app`), ikon adaptif, splash screen.
3. Buat **keystore** upload, simpan aman (cadangan di 2 tempat), aktifkan **Play App Signing**.
4. Atur `versionName` dan `versionCode` (semver; `versionCode` naik tiap build).
5. Hapus log debug, aktifkan obfuscation: `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols`.

### 16.2 Aset dan data toko

- Ikon 512×512, feature graphic 1024×500, 4–8 screenshot, deskripsi singkat dan panjang (bahasa Indonesia).
- Kebijakan privasi (URL publik), form Data Safety, rating konten, kategori (Pendidikan).
- Kontak dukungan (email).

### 16.3 Jalur rilis

**Internal testing** (tim kecil) → **Closed testing** (20–30 tester) → **Production dengan rilis bertahap** (mulai 10–20%, naik jika crash-free ≥ 99%). Tiap tahap harus lolos daftar periksa: tidak ada crash baru, scan dan AI berfungsi, review dan notifikasi normal, audio normal.

### 16.4 CI/CD

- Pipeline: lint → test → build AAB → unggah otomatis ke jalur Internal testing (Fastlane atau Codemagic).
- Simpan keystore dan kunci API sebagai secret CI, bukan di repositori.
- Pakai dua *flavor*: `dev` (server uji) dan `prod`.

### 16.5 iOS (opsional, setelah Android stabil)

Butuh Apple Developer Program (sekitar US$99/tahun) dan Mac untuk build (atau CI macOS). Siapkan juga Sign in with Apple bila ada login pihak ketiga.

## 17. Pasca-Rilis & Monetisasi

- Pantau: retensi D1/D7/D30, tugas di-scan per minggu, kartu direview per sesi, seberapa sering hasil scan diedit, crash, biaya AI per pengguna aktif, ulasan toko.
- Siklus iterasi 2–4 minggu; prioritas dari data, bukan tebakan.
- Model bisnis yang disarankan: **freemium**. Gratis dengan kuota scan harian; premium untuk kuota lebih besar, mapel tambahan, dan statistik. Hindari iklan mengganggu di feed karena merusak pengalaman belajar.
- **Biaya yang perlu dihitung sejak awal:** pemrosesan gambar oleh AI (lebih mahal daripada teks), Supabase di atas batas gratis, akun toko. Ukur biaya per scan saat beta sebelum menentukan harga dan kuota.

## 18. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Tulisan tangan atau rumus salah terbaca | Kartu berisi soal keliru | Layar Cek Hasil wajib, tandai bagian ragu, uji dengan foto nyata |
| AI salah mengoreksi jawaban | Pengguna belajar hal keliru | Verifikasi silang untuk soal hitungan, mode saran untuk uraian dan hafalan, verdict `tidak yakin`, tombol timpa dan lapor |
| Biaya pemrosesan gambar membengkak | Anggaran habis | Kompres gambar, kuota scan harian, cache, model lebih kecil untuk klasifikasi |
| Foto memuat data pribadi | Risiko privasi | Saran crop, hapus foto di server setelah proses, tanpa EXIF |
| Foto halaman buku paket | Masalah hak cipta | Simpan privat, tanpa berbagi publik |
| Hak cipta musik | Aplikasi ditolak atau ditarik | Hanya track bebas royalti dan file milik pengguna |
| Fitur terlalu banyak | Rilis molor | Patuhi batas MVP, sisanya v1.1 |
| Scroll adiktif tanpa belajar | Tujuan produk gagal | Kartu aktif (tebak dulu), sesi berbatas, ringkasan sesi dan jeda |
| Persyaratan Play Store untuk akun baru | Jadwal rilis mundur | Mulai closed testing lebih awal, rekrut tester sejak fase 6 |
| Performa feed di HP murah | Pengalaman buruk | Preload terbatas, profil performa sejak fase 3 |

## 19. Pertanyaan Terbuka (perlu diputuskan)

1. Nama final aplikasi dan identitas visual.
2. Apakah AI memang harus mengoreksi jawaban pengguna? Dokumen ini mengasumsikan ya, dengan hak timpa oleh pengguna.
3. Jenjang utama: SMA saja, atau SMA + kuliah?
4. Daftar mapel bawaan untuk MVP (usulan di bagian 6.3): mana yang perlu ditambah atau dibuang.
5. Akun wajib sejak awal, atau mulai anonim lalu daftar nanti?
6. Model AI dan anggaran bulanan yang disiapkan.
7. Apakah foto asli boleh dicadangkan ke cloud, atau hanya teks dan kartunya?

## 20. Langkah Berikutnya

1. Putuskan pertanyaan terbuka nomor 1–6.
2. Kumpulkan 30–100 foto tugas nyata (cetak dan tulisan tangan) untuk menguji jalur baca foto dan koreksi.
3. Buat wireframe 5 layar inti: Arsip, Scan, Cek Hasil, Feed, Detail Tugas.
4. Siapkan repo Flutter dan skema Drift awal (Fase 2).
