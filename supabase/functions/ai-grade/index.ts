// Supabase Edge Function: POST /ai/grade
// Menerima teks soal & jawaban yang SUDAH dikonfirmasi pengguna di layar Cek Hasil.
// Mengembalikan klasifikasi mapel, topik, tingkat kesulitan (1-5), verdict (correct|wrong|partial|unsure),
// mistake_step, dan confidence (Bagian 6.3, 8, dan 11 PRD).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SYSTEM_PROMPT = `Kamu adalah pemeriksa tugas sekolah Indonesia.
Aturan:
1. Selesaikan soal terlebih dahulu sendiri, lalu bandingkan dengan jawaban pengguna.
2. Untuk soal hitungan (Matematika, Fisika, Kimia), berikan verdict tegas ("correct", "wrong", "partial", atau "unsure" bila ragu).
3. Untuk soal uraian dan hafalan (terutama Pendidikan Agama, Sejarah, Bahasa), JANGAN memberi vonis salah mutlak bila jawaban masih relevan; berikan saran kelengkapan pada field "mistake_step".
4. Kembalikan HANYA JSON dengan skema:
{
  "subject": "matematika|fisika|kimia|biologi|bahasa_indonesia|bahasa_inggris|sejarah|geografi|ekonomi|sosiologi|ppkn|pendidikan_agama|informatika|seni|pjok|umum",
  "topic": "string",
  "question_type": "hitungan|pilihan_ganda|isian|uraian|hafalan",
  "difficulty": 1-5,
  "verdict": "correct|wrong|partial|unsure",
  "mistake_step": "string or null",
  "confidence": 0.0-1.0
}`;

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { question, user_answer } = await req.json();
    if (!question || typeof question !== "string") {
      return new Response(
        JSON.stringify({ error: "Field 'question' wajib diisi." }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY belum diatur." }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                { text: SYSTEM_PROMPT },
                {
                  text: `Soal: ${question}\nJawaban pengguna: ${user_answer ?? "(kosong)"}`,
                },
              ],
            },
          ],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.1,
          },
        }),
      },
    );

    const geminiData = await geminiRes.json();
    const rawText =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
    const parsed = JSON.parse(rawText);

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Gagal memeriksa jawaban", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
