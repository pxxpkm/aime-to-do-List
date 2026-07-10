import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/presentation/widgets/deadline_badge.dart';

void main() {
  group('DeadlineBadge', () {
    testWidgets('shows "今天" when deadline is today', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineBadge(
              deadline: DateTime.now(),
            ),
          ),
        ),
      );

      expect(find.text('今天'), findsOneWidget);
    });

    testWidgets('shows "明天" when deadline is tomorrow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineBadge(
              deadline: DateTime.now().add(const Duration(days: 1)),
            ),
          ),
        ),
      );

      expect(find.text('明天'), findsOneWidget);
    });

    testWidgets('shows "還有 N 天" for future dates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineBadge(
              deadline: DateTime.now().add(const Duration(days: 5)),
            ),
          ),
        ),
      );

      expect(find.text('還有 5 天'), findsOneWidget);
    });

    testWidgets('shows "已逾期" for past dates', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeadlineBadge(
              deadline: DateTime.now().subtract(const Duration(days: 2)),
            ),
          ),
        ),
      );

      expect(find.text('已逾期'), findsOneWidget);
    });
  });
}
