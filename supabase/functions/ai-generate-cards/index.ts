// Supabase Edge Function: POST /ai/generate-cards
// Menghasilkan 3-8 kartu belajar per soal sesuai Bagian 6.4 & 8 PRD:
// - question (Soal ulang)
// - mistake (Kartu kesalahan, hanya bila jawaban salah/sebagian)
// - concept (Konsep / rumus di balik soal)
// - flashcard (Pasangan istilah-definisi)
// - variant (Variasi soal dengan angka berbeda, khusus soal hitungan Matematika/Fisika/Kimia)
// Guardrail Pendidikan Agama: DILARANG mengarang ayat, hadis, atau doa di luar yang tertulis pada tugas pengguna.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SYSTEM_PROMPT = `Buat 3 sampai 6 kartu belajar singkat (satu halaman satu pikiran) dari soal dan jawaban tugas berikut.
Aturan ketat:
1. Gunakan Bahasa Indonesia dengan sapaan "kamu", kalimat tenang dan langsung.
2. Untuk Matematika, Fisika, dan Kimia, tulis rumus dalam LaTeX ($...$) dan sertakan 1 kartu bertipe "variant" (angka berbeda).
3. Untuk Pendidikan Agama, HANYA gunakan ayat, hadis, atau doa yang ada di teks tugas pengguna; JANGAN PERNAH mengarang kutipan baru.
4. Jika verdict adalah "wrong" atau "partial", wajib buat 1 kartu bertipe "mistake" yang mengisi "wrong_step", "correction_margin_note", dan "correct_step".
5. Kembalikan HANYA JSON dengan skema:
{
  "cards": [
    {
      "type": "question|mistake|concept|flashcard|variant",
      "prompt_text": "string",
      "answer_text": "string",
      "explanation_text": "string",
      "wrong_step": "string or null",
      "correction_margin_note": "string or null",
      "correct_step": "string or null",
      "deep_dive_steps": ["Langkah 1...", "Langkah 2..."]
    }
  ]
}`;

serve(async (req: Request) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const { subject, topic, question, user_answer, verdict, mistake_step } =
      await req.json();

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
                  text: JSON.stringify({
                    subject,
                    topic,
                    question,
                    user_answer,
                    verdict,
                    mistake_step,
                  }),
                },
              ],
            },
          ],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.2,
          },
        }),
      },
    );

    const geminiData = await geminiRes.json();
    const rawText =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? '{"cards":[]}';
    const parsed = JSON.parse(rawText);

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Gagal membuat kartu", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
