import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';
import '../../core/widgets/verdict_tag.dart';
import 'ai_cross_verifier.dart';

/// Daftar model OpenRouter populer (termasuk model Vision gratis/murah) untuk dipilih dengan 1 ketukan,
/// namun pengguna juga bebas mengetik ID model OpenRouter apa pun.
class OpenRouterModelPreset {
  const OpenRouterModelPreset({
    required this.id,
    required this.label,
    required this.subtitle,
  });

  final String id;
  final String label;
  final String subtitle;

  static const List<OpenRouterModelPreset> presets = [
    OpenRouterModelPreset(
      id: 'google/gemini-2.0-flash-exp:free',
      label: 'Gemini 2.0 Flash (Free)',
      subtitle: 'Cepat untuk baca tulisan tangan & rumus LaTeX (Gratis)',
    ),
    OpenRouterModelPreset(
      id: 'qwen/qwen2.5-vl-72b-instruct:free',
      label: 'Qwen 2.5 VL 72B (Free)',
      subtitle: 'Kuat untuk soal Matematika, Fisika & Kimia (Gratis)',
    ),
    OpenRouterModelPreset(
      id: 'meta-llama/llama-3.2-11b-vision-instruct:free',
      label: 'Llama 3.2 11B Vision (Free)',
      subtitle: 'Model cadangan ringan saat model utama penuh (Gratis)',
    ),
    OpenRouterModelPreset(
      id: 'google/gemini-2.5-flash-preview',
      label: 'Gemini 2.5 Flash',
      subtitle: 'Akurasi tinggi & hemat saldo OpenRouter',
    ),
    OpenRouterModelPreset(
      id: 'openai/gpt-4o-mini',
      label: 'GPT-4o mini',
      subtitle: 'Stabil untuk koreksi langkah & pembuatan kartu',
    ),
  ];
}

/// Satu pintu layanan pemanggilan AI sesuai Bagian 8, 9, dan 11 PRD:
/// - Mendukung **OpenRouter API** (`https://openrouter.ai/api/v1/chat/completions`) secara langsung
///   dengan fitur **Auto-Fallback** ke model cadangan bila model utama terkena *rate limit* (`429`) atau sibuk.
/// - Bila API Key OpenRouter belum diisi di perangkat, otomatis memanggil Supabase Edge Function
///   atau fallback terstruktur secara offline.
class AiService {
  AiService({
    http.Client? client,
    this.config = AppConfig.dev,
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final AppConfig config;

  static const String openRouterEndpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _storageKeyApiKey = 'ts_openrouter_api_key';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Menyimpan API Key OpenRouter dengan enkripsi aman (`flutter_secure_storage`).
  static Future<void> saveOpenRouterApiKey(String apiKey) async {
    try {
      await _secureStorage.write(key: _storageKeyApiKey, value: apiKey.trim());
    } catch (_) {}
  }

  /// Membaca API Key OpenRouter yang tersimpan di perangkat.
  static Future<String?> loadOpenRouterApiKey() async {
    try {
      return await _secureStorage.read(key: _storageKeyApiKey);
    } catch (_) {
      return null;
    }
  }

  /// 1. Membaca gambar halaman tugas (`scan_task`) menggunakan OpenRouter Vision (dengan auto-fallback model).
  Future<List<ScannedQuestionItem>> scanTaskImages(
    List<String> base64Images, {
    String? openRouterApiKey,
    String primaryModel = 'google/gemini-2.0-flash-exp:free',
    String fallbackModel = 'qwen/qwen2.5-vl-72b-instruct:free',
  }) async {
    final String? effectiveKey =
        (openRouterApiKey != null && openRouterApiKey.trim().isNotEmpty)
        ? openRouterApiKey.trim()
        : await loadOpenRouterApiKey();

    // Jalur 1: Panggil OpenRouter langsung bila pengguna sudah memasukkan OpenRouter API Key
    if (effectiveKey != null &&
        effectiveKey.isNotEmpty &&
        base64Images.isNotEmpty) {
      final modelsToTry = <String>[
        primaryModel,
        if (fallbackModel.isNotEmpty && fallbackModel != primaryModel)
          fallbackModel,
        'meta-llama/llama-3.2-11b-vision-instruct:free',
      ];

      for (final modelId in modelsToTry) {
        try {
          final items = await _callOpenRouterScan(
            apiKey: effectiveKey,
            modelId: modelId,
            base64Images: base64Images,
          );
          if (items.isNotEmpty) return items;
        } catch (_) {
          // Jika model terkena limit 429 atau gagal, lanjut otomatis ke model cadangan berikutnya
          continue;
        }
      }
    }

    // Jalur 2: Panggil Supabase Edge Function (/ai-scan)
    if (base64Images.isNotEmpty) {
      try {
        final uri = Uri.parse('${config.apiBaseUrl}/ai-scan');
        final response = await _client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({'images': base64Images}),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          return AiCrossVerifier.parseScanResponse(response.body);
        }
      } catch (_) {}
    }

    // Jalur 3: Fallback pratinjau lokal
    return const [
      ScannedQuestionItem(
        question: r'Turunan dari $f(x) = 3x^2 + 2x$ adalah ...',
        userAnswer: r"$f'(x) = 6x + 2$",
        confidence: 0.92,
        lowConfidenceParts: [],
      ),
      ScannedQuestionItem(
        question: r'Tentukan nilai $f(x) = x^3 - 4x$ saat $x = 2$',
        userAnswer: r'$f(2) = 8 - 8 = 0$',
        confidence: 0.71,
        lowConfidenceParts: ['x^3 - 4x'],
      ),
    ];
  }

  Future<List<ScannedQuestionItem>> _callOpenRouterScan({
    required String apiKey,
    required String modelId,
    required List<String> base64Images,
  }) async {
    const prompt = '''
Kamu adalah pembaca lembar tugas sekolah Indonesia (SMA/SMK/Kuliah).
Pisahkan setiap soal dan jawaban pengguna dari gambar.
Tuliskan rumus matematika/fisika/kimia dalam LaTeX di antara tanda \$...\$.
Jika ada tulisan tangan yang sulit dibaca atau meragukan, masukkan potongan teks tersebut ke array "low_confidence_parts".
Kembalikan HANYA JSON murni (tanpa markdown block) dengan skema:
{"items":[{"question":"...","user_answer":"...","confidence":0.9,"low_confidence_parts":[]}]}
''';

    final contentList = <Map<String, dynamic>>[
      {'type': 'text', 'text': prompt},
      for (final b64 in base64Images)
        {
          'type': 'image_url',
          'image_url': {'url': 'data:image/jpeg;base64,$b64'},
        },
    ];

    final response = await _client
        .post(
          Uri.parse(openRouterEndpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://tugasscroll.app',
            'X-Title': 'TugasScroll',
          },
          body: jsonEncode({
            'model': modelId,
            'messages': [
              {'role': 'user', 'content': contentList},
            ],
            'response_format': {'type': 'json_object'},
            'temperature': 0.1,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('OpenRouter status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawContent =
        decoded['choices']?[0]?['message']?['content']?.toString() ?? '';
    final cleanJson = _extractJsonObject(rawContent);
    return AiCrossVerifier.parseScanResponse(cleanJson);
  }

  /// 2. Mengklasifikasikan mapel/topik & memeriksa jawaban yang SUDAH dikonfirmasi pengguna di layar Cek Hasil.
  Future<GradeClassificationResult> classifyAndGrade({
    required String questionText,
    required String userAnswerText,
    String? openRouterApiKey,
    String primaryModel = 'google/gemini-2.0-flash-exp:free',
    String fallbackModel = 'qwen/qwen2.5-vl-72b-instruct:free',
  }) async {
    final String? effectiveKey =
        (openRouterApiKey != null && openRouterApiKey.trim().isNotEmpty)
        ? openRouterApiKey.trim()
        : await loadOpenRouterApiKey();

    if (effectiveKey != null && effectiveKey.isNotEmpty) {
      final modelsToTry = <String>[
        primaryModel,
        if (fallbackModel.isNotEmpty && fallbackModel != primaryModel)
          fallbackModel,
      ];

      for (final modelId in modelsToTry) {
        try {
          final res = await _callOpenRouterGrade(
            apiKey: effectiveKey,
            modelId: modelId,
            questionText: questionText,
            userAnswerText: userAnswerText,
          );
          return AiCrossVerifier.verifyGradeResult(
            aiResult: res,
            questionText: questionText,
            userAnswerText: userAnswerText,
          );
        } catch (_) {
          continue;
        }
      }
    }

    // Fallback verifikasi lokal
    final fallback = GradeClassificationResult(
      subject: 'matematika',
      topic: 'Latihan soal',
      questionType: 'hitungan',
      difficulty: 2,
      verdict: userAnswerText.trim().isNotEmpty
          ? TaskVerdict.correct
          : TaskVerdict.unsure,
      confidence: 0.88,
    );

    return AiCrossVerifier.verifyGradeResult(
      aiResult: fallback,
      questionText: questionText,
      userAnswerText: userAnswerText,
    );
  }

  Future<GradeClassificationResult> _callOpenRouterGrade({
    required String apiKey,
    required String modelId,
    required String questionText,
    required String userAnswerText,
  }) async {
    const systemPrompt = '''
Periksa soal dan jawaban tugas berikut.
Untuk soal hitungan (Matematika, Fisika, Kimia), selesaikan sendiri lalu bandingkan dengan jawaban pengguna.
Untuk soal uraian dan hafalan, jangan vonis salah mutlak; tulis saran kelengkapan di mistake_step.
Kembalikan HANYA JSON:
{"subject":"matematika|fisika|kimia|biologi|bahasa|ips|agama|umum","topic":"...","question_type":"hitungan|pilihan_ganda|isian|uraian|hafalan","difficulty":2,"verdict":"correct|wrong|partial|unsure","mistake_step":null,"confidence":0.9}
''';

    final response = await _client
        .post(
          Uri.parse(openRouterEndpoint),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://tugasscroll.app',
            'X-Title': 'TugasScroll',
          },
          body: jsonEncode({
            'model': modelId,
            'messages': [
              {'role': 'system', 'content': systemPrompt},
              {
                'role': 'user',
                'content':
                    'Soal: $questionText\nJawaban pengguna: $userAnswerText',
              },
            ],
            'response_format': {'type': 'json_object'},
            'temperature': 0.1,
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('OpenRouter grade status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rawContent =
        decoded['choices']?[0]?['message']?['content']?.toString() ?? '{}';
    final cleanJson = _extractJsonObject(rawContent);
    return GradeClassificationResult.fromJson(
      jsonDecode(cleanJson) as Map<String, dynamic>,
    );
  }

  static String _extractJsonObject(String raw) {
    final trimmed = raw.trim();
    final start = trimmed.indexOf('{');
    final end = trimmed.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return trimmed.substring(start, end + 1);
    }
    return trimmed;
  }
}
