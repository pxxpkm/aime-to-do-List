import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:acg_todo/domain/entities/item.dart';
import 'package:acg_todo/presentation/widgets/poster_card.dart';

void main() {
  group('PosterCard', () {
    final mockItem = Item(
      id: 'test_1',
      userId: 'user_1',
      type: 'anime',
      title: 'Test Anime',
      posterUrl: 'https://example.com/poster.jpg',
      totalUnits: 12,
      currentUnits: 6,
      unitLabel: '集',
    );

    testWidgets('renders title and progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 240,
              child: PosterCard(
                item: mockItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Test Anime'), findsOneWidget);
      expect(find.text('6/12 集'), findsOneWidget);
    });

    testWidgets('renders fallback when no poster', (tester) async {
      final itemNoPoster = mockItem.copyWith(posterUrl: null);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 240,
              child: PosterCard(
                item: itemNoPoster,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('increment button fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              height: 240,
              child: PosterCard(
                item: mockItem,
                onTap: () {},
                onIncrement: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      expect(tapped, isTrue);
    });
  });
}
