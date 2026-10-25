import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tugasscroll/app.dart';
import 'package:tugasscroll/core/theme/ts_palette.dart';

void main() {
  testWidgets('TugasScroll merender tema Malam default dan komponen halaman', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TugasScrollApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Memastikan wordmark dan tab bar bawah tampil
    expect(find.text('TugasScroll'), findsOneWidget);
    expect(find.text('Arsip'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Belajar'), findsOneWidget);
    expect(find.text('Catatan'), findsOneWidget);

    // Memastikan tombol penilaian GradeBar tampil di Feed Belajar
    expect(find.text('Lupa'), findsOneWidget);
    expect(find.text('Susah'), findsOneWidget);
    expect(find.text('Oke'), findsOneWidget);
    expect(find.text('Mudah'), findsOneWidget);

    // Memastikan token warna default adalah Malam (#12172A)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold.backgroundColor, TsPalette.malam.bg);
  });
}
