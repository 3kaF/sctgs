-- Skema Database TugasScroll v2.0 (Identik antara SQLite/Drift lokal & Supabase Postgres)
-- Semua tabel menggunakan UUID, created_at, updated_at, dan deleted_at (soft delete).

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Mapel (bawaan sistem + buatan pengguna)
CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY,
  user_id UUID NULL,            -- NULL = mapel bawaan sistem
  name TEXT NOT NULL,           -- Matematika, Fisika, Kimia, ..., Umum
  color TEXT,                   -- Kunci rumpun warna sampul (matematika, fisika, kimia, biologi, ips, bahasa, agama, umum)
  icon TEXT,                    -- Nama ikon Phosphor
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 2. Satu sesi scan = beberapa foto yang diproses bersama
CREATE TABLE IF NOT EXISTS scans (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',    -- pending | processing | done | failed
  page_count INT NOT NULL DEFAULT 1,
  processed_at TIMESTAMPTZ NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 3. Gambar halaman tugas
CREATE TABLE IF NOT EXISTS task_images (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  scan_id UUID REFERENCES scans(id) ON DELETE CASCADE,
  page_no SMALLINT NOT NULL DEFAULT 1,
  local_path TEXT NOT NULL,         -- penyimpanan privat app
  remote_path TEXT NULL,            -- hanya saat diproses / bila cadangan aktif
  width INT NULL,
  height INT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 4. Satu baris = satu soal yang sudah dikerjakan
CREATE TABLE IF NOT EXISTS tasks (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  subject_id UUID REFERENCES subjects(id),
  scan_id UUID NULL REFERENCES scans(id) ON DELETE SET NULL,
  title TEXT,                       -- ringkasan singkat soal
  question_text TEXT NOT NULL,      -- teks soal terverifikasi (LaTeX bila ada)
  user_answer_text TEXT,            -- jawaban yang dikerjakan pengguna
  topic TEXT,
  done_on DATE NOT NULL DEFAULT CURRENT_DATE,
  question_type TEXT,               -- hitungan | pilihan_ganda | isian | uraian | hafalan
  difficulty SMALLINT DEFAULT 2,    -- 1..5
  mastery SMALLINT DEFAULT 0,       -- 0 baru, 1 lemah, 2 cukup, 3 kuat
  ai_verdict TEXT,                  -- correct | wrong | partial | unsure
  mistake_step TEXT,
  user_verdict TEXT NULL,           -- timpaan pengguna: correct | wrong
  ai_confidence REAL,
  needs_check BOOLEAN DEFAULT FALSE,
  source TEXT DEFAULT 'scan',       -- scan | manual
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 5. Kartu belajar AI & buatan pengguna
CREATE TABLE IF NOT EXISTS cards (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id),
  type TEXT NOT NULL,               -- question | mistake | concept | flashcard | variant | note
  content JSONB NOT NULL,           -- soal/teks (mendukung LaTeX & Arab RTL)
  answer JSONB NULL,
  explanation TEXT NULL,
  generated_by TEXT DEFAULT 'ai',   -- ai | user
  reported BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 6. Jadwal review per kartu (pengulangan berjarak SM-2)
CREATE TABLE IF NOT EXISTS card_progress (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  card_id UUID REFERENCES cards(id) ON DELETE CASCADE,
  seen_count INT DEFAULT 0,
  lapses INT DEFAULT 0,             -- berapa kali dinilai Lupa
  last_grade SMALLINT NULL,         -- 0 Lupa, 1 Susah, 2 Oke, 3 Mudah
  ease REAL DEFAULT 2.5,
  interval_days INT DEFAULT 0,
  next_review_at TIMESTAMPTZ NULL,
  last_seen_at TIMESTAMPTZ NULL,
  is_starred BOOLEAN DEFAULT FALSE,
  repeat_later BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL,
  UNIQUE (user_id, card_id)
);

-- 7. Catatan pribadi per tugas atau kartu
CREATE TABLE IF NOT EXISTS notes (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  task_id UUID NULL REFERENCES tasks(id) ON DELETE CASCADE,
  card_id UUID NULL REFERENCES cards(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  show_in_feed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 8. Playlist musik latar per mapel
CREATE TABLE IF NOT EXISTS playlists (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  name TEXT NOT NULL,
  subject_id UUID NULL REFERENCES subjects(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 9. Track audio (bundled bebas royalti & file lokal)
CREATE TABLE IF NOT EXISTS tracks (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  playlist_id UUID REFERENCES playlists(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  source_type TEXT NOT NULL,        -- bundled | local_file
  uri TEXT NOT NULL,
  duration_sec INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ NULL
);

-- 10. Riwayat sesi belajar
CREATE TABLE IF NOT EXISTS study_sessions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  feed_mode TEXT NOT NULL,          -- math | chem | mixed | subject_id
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at TIMESTAMPTZ NULL,
  cards_viewed INT DEFAULT 0,
  cards_correct INT DEFAULT 0
);

-- 11. Antrean pekerjaan AI (untuk offline queue & pemantauan token)
CREATE TABLE IF NOT EXISTS ai_jobs (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  type TEXT NOT NULL,               -- scan | grade | generate_cards
  scan_id UUID NULL REFERENCES scans(id) ON DELETE CASCADE,
  task_id UUID NULL REFERENCES tasks(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'queued', -- queued | done | failed
  tokens_used INT DEFAULT 0,
  error TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indeks penting (Bagian 10.1 PRD)
CREATE INDEX IF NOT EXISTS idx_tasks_user_subject_done ON tasks(user_id, subject_id, done_on);
CREATE INDEX IF NOT EXISTS idx_tasks_user_needs_check ON tasks(user_id, needs_check);
CREATE INDEX IF NOT EXISTS idx_cards_user_subject ON cards(user_id, subject_id);
CREATE INDEX IF NOT EXISTS idx_card_progress_user_next_review ON card_progress(user_id, next_review_at);
CREATE INDEX IF NOT EXISTS idx_scans_user_status ON scans(user_id, status);

-- Pencarian teks penuh di Postgres menggunakan tsvector
CREATE INDEX IF NOT EXISTS idx_tasks_fts ON tasks USING GIN (to_tsvector('indonesian', coalesce(title, '') || ' ' || coalesce(question_text, '') || ' ' || coalesce(topic, '')));
CREATE INDEX IF NOT EXISTS idx_notes_fts ON notes USING GIN (to_tsvector('indonesian', body));

-- Row Level Security (Bagian 10.2 PRD)
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE scans ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE playlists ENABLE ROW LEVEL SECURITY;
ALTER TABLE tracks ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_jobs ENABLE ROW LEVEL SECURITY;

-- Kebijakan RLS: Mapel bawaan (user_id IS NULL) bisa dibaca semua, baris milik pengguna hanya untuk auth.uid()
CREATE POLICY subjects_select_policy ON subjects FOR SELECT USING (user_id IS NULL OR user_id = auth.uid());
CREATE POLICY subjects_modify_policy ON subjects FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY user_isolation_scans ON scans FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_task_images ON task_images FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_tasks ON tasks FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_cards ON cards FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_card_progress ON card_progress FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_notes ON notes FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_playlists ON playlists FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_tracks ON tracks FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_study_sessions ON study_sessions FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY user_isolation_ai_jobs ON ai_jobs FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
