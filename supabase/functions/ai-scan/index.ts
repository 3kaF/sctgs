// Supabase Edge Function: POST /ai/scan
// Membaca foto halaman tugas dengan LLM Vision (Gemini / OpenAI) dan mengembalikan JSON terstruktur:
// { "items": [{ "question": "...", "user_answer": "...", "confidence": 0.88, "low_confidence_parts": [] }] }
// Foto langsung dihapus dari memori/storage segera setelah pembacaan selesai (Bagian 6.2 & 10.2 PRD).

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

const SYSTEM_PROMPT = `Kamu adalah pembaca lembar tugas sekolah Indonesia (SMA/SMK/Kuliah).
Pisahkan setiap soal dan jawaban tulisan tangan/cetak pengguna dari gambar.
Tuliskan rumus matematika/fisika/kimia dalam format LaTeX di antara tanda $...$.
Tuliskan teks Arab apa adanya dengan harakat bila terlihat, jangan mengarang kutipan.
Jika ada tulisan tangan yang sulit dibaca atau meragukan, masukkan potongan teks tersebut ke array "low_confidence_parts".
Kembalikan HANYA JSON valid dengan skema:
{
  "items": [
    {
      "question": "string",
      "user_answer": "string",
      "confidence": 0.0-1.0,
      "low_confidence_parts": ["string"]
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
    const body = await req.json();
    const imagesBase64: string[] = Array.isArray(body.images) ? body.images : [];

    if (imagesBase64.length === 0 || imagesBase64.length > 10) {
      return new Response(
        JSON.stringify({ error: "Jumlah halaman foto harus antara 1 sampai 10." }),
        { status: 400, headers: { "Content-Type": "application/json" } },
      );
    }

    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "Server AI belum dikonfigurasi (GEMINI_API_KEY)." }),
        { status: 500, headers: { "Content-Type": "application/json" } },
      );
    }

    const parts = [
      { text: SYSTEM_PROMPT },
      ...imagesBase64.map((b64) => ({
        inline_data: { mime_type: "image/jpeg", data: b64 },
      })),
    ];

    const geminiRes = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{ parts }],
          generationConfig: {
            responseMimeType: "application/json",
            temperature: 0.1,
          },
        }),
      },
    );

    const geminiData = await geminiRes.json();
    const rawText =
      geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? '{"items":[]}';
    const parsed = JSON.parse(rawText);

    return new Response(JSON.stringify(parsed), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Gagal memproses gambar", detail: String(err) }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }
});
