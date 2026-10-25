import 'package:flutter/material.dart';

/// Kelompok warna sampul mapel (Bagian 3.3 design.md).
/// Hanya dipakai sebagai penanda: garis tepi kartu, titik di chip, sampul di Arsip.
/// Tidak pernah dipakai untuk teks atau status.
enum SubjectCluster {
  matematika,
  fisika,
  kimia,
  biologi,
  ips, // Sejarah, Geografi, Ekonomi, Sosiologi, PPKn
  bahasa, // Bahasa Indonesia, Bahasa Inggris
  agama, // Pendidikan Agama
  umum, // Informatika, Seni, PJOK, Lainnya dan Umum
}

/// Jenis latar kertas untuk `PageCard` (Bagian 5 design.md).
enum PaperPattern {
  /// Kertas kotak-kotak (24 dp, opasitas ~6%) untuk mapel hitungan (Matematika, Fisika, Kimia).
  grid,

  /// Kertas bergaris untuk Catatan dan mapel Bahasa.
  ruled,

  /// Polos untuk mapel lainnya.
  plain,
}

/// Token warna resmi TugasScroll sesuai Bagian 3 & 14 `design.md`.
/// Disimpan sebagai `ThemeExtension<TsPalette>` agar tidak ada hex yang di-hardcode di widget.
@immutable
class TsPalette extends ThemeExtension<TsPalette> {
  const TsPalette({
    required this.isNight,
    required this.bg,
    required this.page,
    required this.raised,
    required this.ink,
    required this.pencil,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.stabilo,
    required this.stabiloHighlightOpacity,
    required this.penRed,
    required this.penGreen,
    required this.penBlue,
    required this.line,
    required this.coverMath,
    required this.coverPhysics,
    required this.coverChemistry,
    required this.coverBiology,
    required this.coverIps,
    required this.coverLanguage,
    required this.coverReligion,
    required this.coverGeneral,
  });

  final bool isNight;
  final Color bg;
  final Color page;
  final Color raised;
  final Color ink;
  final Color pencil;
  final Color primaryAction;
  final Color onPrimaryAction;
  final Color stabilo;
  final double stabiloHighlightOpacity;
  final Color penRed;
  final Color penGreen;
  final Color penBlue;
  final Color line;

  // Warna sampul mapel per rumpun (Bagian 3.3 design.md)
  final Color coverMath;
  final Color coverPhysics;
  final Color coverChemistry;
  final Color coverBiology;
  final Color coverIps;
  final Color coverLanguage;
  final Color coverReligion;
  final Color coverGeneral;

  /// Tema Malam (Default - Bagian 3.1 design.md)
  static const malam = TsPalette(
    isNight: true,
    bg: Color(0xFF12172A), // Tinta malam
    page: Color(0xFF1B2338), // Halaman
    raised: Color(0xFF252F4A), // Halaman terangkat
    ink: Color(0xFFECEFF6), // Kapur (15.4:1 di bg, 13.6:1 di page)
    pencil: Color(0xFFA3ADC4), // Pensil (6.9:1 di page)
    primaryAction: Color(0xFFF5D547), // Stabilo sebagai tombol utama di Malam
    onPrimaryAction: Color(0xFF12172A), // Teks bg di atas stabilo (12.3:1)
    stabilo: Color(0xFFF5D547), // Stabilo
    stabiloHighlightOpacity: 0.25, // Opasitas 25% di Malam
    penRed: Color(0xFFFF8A8A), // Pulpen koreksi
    penGreen: Color(0xFF6FD3A0), // Centang
    penBlue: Color(0xFF8FB2FF), // Pulpen biru
    line: Color(0x1AECEFF6), // #ECEFF6 pada 10%
    coverMath: Color(0xFF8FB2FF),
    coverPhysics: Color(0xFF5CC8E0),
    coverChemistry: Color(0xFFB7A1FF),
    coverBiology: Color(0xFF8FD27A),
    coverIps: Color(0xFFFFA866),
    coverLanguage: Color(0xFFFF9EC0),
    coverReligion: Color(0xFF5ED3B7),
    coverGeneral: Color(0xFFA3ADC4),
  );

  /// Tema Siang (Bagian 3.2 design.md)
  static const siang = TsPalette(
    isNight: false,
    bg: Color(0xFFF6F8FC), // Meja
    page: Color(0xFFFFFFFF), // Folio
    raised: Color(0xFFEAF0FB), // Halaman terangkat
    ink: Color(0xFF14203D), // Tinta (16.1:1 di page)
    pencil: Color(0xFF4F5B78), // Pensil (6.8:1 di page)
    primaryAction: Color(0xFF2347C8), // Biru pulpen sebagai tombol utama di Siang
    onPrimaryAction: Color(0xFFFFFFFF), // Teks putih (7.5:1)
    stabilo: Color(0xFFFFE066), // Stabilo
    stabiloHighlightOpacity: 0.70, // Opasitas 70% di Siang
    penRed: Color(0xFFC62F3A), // Pulpen koreksi
    penGreen: Color(0xFF1E7A4D), // Centang
    penBlue: Color(0xFF2347C8), // Biru pulpen
    line: Color(0xFFCFDAF0), // Garis rapi
    coverMath: Color(0xFF3F63D8),
    coverPhysics: Color(0xFF0E7F99),
    coverChemistry: Color(0xFF7B58D6),
    coverBiology: Color(0xFF4A8F2D),
    coverIps: Color(0xFFC9661A),
    coverLanguage: Color(0xFFC2386F),
    coverReligion: Color(0xFF12806C),
    coverGeneral: Color(0xFF66708A),
  );

  /// Mengambil warna sampul berdasarkan rumpun mapel atau kunci warna string.
  Color coverColorFor(SubjectCluster cluster) {
    switch (cluster) {
      case SubjectCluster.matematika:
        return coverMath;
      case SubjectCluster.fisika:
        return coverPhysics;
      case SubjectCluster.kimia:
        return coverChemistry;
      case SubjectCluster.biologi:
        return coverBiology;
      case SubjectCluster.ips:
        return coverIps;
      case SubjectCluster.bahasa:
        return coverLanguage;
      case SubjectCluster.agama:
        return coverReligion;
      case SubjectCluster.umum:
        return coverGeneral;
    }
  }

  /// Mengambil warna sampul berdasarkan nama kode rumpun di database (`math`, `physics`, dll.).
  Color coverColorByKey(String? colorKey) {
    switch (colorKey?.toLowerCase()) {
      case 'matematika':
      case 'math':
        return coverMath;
      case 'fisika':
      case 'physics':
        return coverPhysics;
      case 'kimia':
      case 'chemistry':
        return coverChemistry;
      case 'biologi':
      case 'biology':
        return coverBiology;
      case 'ips':
      case 'sejarah':
      case 'geografi':
      case 'ekonomi':
      case 'sosiologi':
      case 'ppkn':
        return coverIps;
      case 'bahasa':
      case 'bahasa_indonesia':
      case 'bahasa_inggris':
        return coverLanguage;
      case 'agama':
      case 'pendidikan_agama':
        return coverReligion;
      default:
        return coverGeneral;
    }
  }

  /// Menentukan pola kertas otomatis dari kode mapel (Bagian 5 design.md).
  static PaperPattern paperPatternForSubject(String? subjectKey, {bool isNote = false}) {
    if (isNote) return PaperPattern.ruled;
    switch (subjectKey?.toLowerCase()) {
      case 'matematika':
      case 'math':
      case 'fisika':
      case 'physics':
      case 'kimia':
      case 'chemistry':
        return PaperPattern.grid;
      case 'bahasa':
      case 'bahasa_indonesia':
      case 'bahasa_inggris':
        return PaperPattern.ruled;
      default:
        return PaperPattern.plain;
    }
  }

  @override
  TsPalette copyWith({
    bool? isNight,
    Color? bg,
    Color? page,
    Color? raised,
    Color? ink,
    Color? pencil,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? stabilo,
    double? stabiloHighlightOpacity,
    Color? penRed,
    Color? penGreen,
    Color? penBlue,
    Color? line,
    Color? coverMath,
    Color? coverPhysics,
    Color? coverChemistry,
    Color? coverBiology,
    Color? coverIps,
    Color? coverLanguage,
    Color? coverReligion,
    Color? coverGeneral,
  }) {
    return TsPalette(
      isNight: isNight ?? this.isNight,
      bg: bg ?? this.bg,
      page: page ?? this.page,
      raised: raised ?? this.raised,
      ink: ink ?? this.ink,
      pencil: pencil ?? this.pencil,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      stabilo: stabilo ?? this.stabilo,
      stabiloHighlightOpacity:
          stabiloHighlightOpacity ?? this.stabiloHighlightOpacity,
      penRed: penRed ?? this.penRed,
      penGreen: penGreen ?? this.penGreen,
      penBlue: penBlue ?? this.penBlue,
      line: line ?? this.line,
      coverMath: coverMath ?? this.coverMath,
      coverPhysics: coverPhysics ?? this.coverPhysics,
      coverChemistry: coverChemistry ?? this.coverChemistry,
      coverBiology: coverBiology ?? this.coverBiology,
      coverIps: coverIps ?? this.coverIps,
      coverLanguage: coverLanguage ?? this.coverLanguage,
      coverReligion: coverReligion ?? this.coverReligion,
      coverGeneral: coverGeneral ?? this.coverGeneral,
    );
  }

  @override
  TsPalette lerp(covariant ThemeExtension<TsPalette>? other, double t) {
    if (other is! TsPalette) return this;
    return TsPalette(
      isNight: t < 0.5 ? isNight : other.isNight,
      bg: Color.lerp(bg, other.bg, t)!,
      page: Color.lerp(page, other.page, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      pencil: Color.lerp(pencil, other.pencil, t)!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      onPrimaryAction: Color.lerp(onPrimaryAction, other.onPrimaryAction, t)!,
      stabilo: Color.lerp(stabilo, other.stabilo, t)!,
      stabiloHighlightOpacity:
          stabiloHighlightOpacity +
          (other.stabiloHighlightOpacity - stabiloHighlightOpacity) * t,
      penRed: Color.lerp(penRed, other.penRed, t)!,
      penGreen: Color.lerp(penGreen, other.penGreen, t)!,
      penBlue: Color.lerp(penBlue, other.penBlue, t)!,
      line: Color.lerp(line, other.line, t)!,
      coverMath: Color.lerp(coverMath, other.coverMath, t)!,
      coverPhysics: Color.lerp(coverPhysics, other.coverPhysics, t)!,
      coverChemistry: Color.lerp(coverChemistry, other.coverChemistry, t)!,
      coverBiology: Color.lerp(coverBiology, other.coverBiology, t)!,
      coverIps: Color.lerp(coverIps, other.coverIps, t)!,
      coverLanguage: Color.lerp(coverLanguage, other.coverLanguage, t)!,
      coverReligion: Color.lerp(coverReligion, other.coverReligion, t)!,
      coverGeneral: Color.lerp(coverGeneral, other.coverGeneral, t)!,
    );
  }
}

/// Extension praktis agar di widget cukup memanggil `context.tsPalette`.
extension TsPaletteBuildContext on BuildContext {
  TsPalette get tsPalette =>
      Theme.of(this).extension<TsPalette>() ?? TsPalette.malam;
}
