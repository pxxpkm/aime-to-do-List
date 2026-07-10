import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/core/theme/app_colors.dart';
import 'package:acg_todo/presentation/widgets/progress_ring.dart';

void main() {
  group('AnimatedProgressRing', () {
    testWidgets('renders with progress value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressRing(
              progress: 0.5,
              color: AppColors.anime,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedProgressRing), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressRing(
              progress: 0.75,
              color: AppColors.manga,
              child: Text('75%'),
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('clamps progress to 0-1 range', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedProgressRing(
              progress: 1.5,
              color: AppColors.game,
            ),
          ),
        ),
      );

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, lessThanOrEqualTo(1.0));
    });
  });
}
