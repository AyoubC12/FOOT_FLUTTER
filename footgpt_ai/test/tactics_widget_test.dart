import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:footgpt_ai/app/theme/app_theme.dart';
import 'package:footgpt_ai/features/tactics/presentation/screens/tactics_screen.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('tactical board shows formations and an interactive pitch', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TacticsScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Tactical analysis'), findsOneWidget);
    expect(find.text('4-3-3'), findsWidgets);
    expect(find.text('4-4-2'), findsWidgets);
    expect(find.text('3-5-2'), findsOneWidget);
    expect(find.text('4-2-3-1'), findsOneWidget);
    expect(find.text('Add player'), findsOneWidget);
    expect(find.text('AI tactical notes'), findsOneWidget);

    await tester.tap(find.text('4-4-2').first);
    await tester.pump();
    expect(find.textContaining('4-4-2'), findsWidgets);
  });
}
