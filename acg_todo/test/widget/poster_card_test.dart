import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    Widget wrap(Widget child) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 320,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('renders title and progress', (tester) async {
      await tester.pumpWidget(
        wrap(
          PosterCard(
            item: mockItem,
            titleSimpToTrad: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Anime'), findsOneWidget);
      expect(find.text('6/12 集'), findsOneWidget);
    });

    testWidgets('renders fallback when no poster', (tester) async {
      final itemNoPoster = mockItem.copyWith(posterUrl: null);

      await tester.pumpWidget(
        wrap(
          PosterCard(
            item: itemNoPoster,
            titleSimpToTrad: false,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.movie_outlined), findsOneWidget);
    });

    testWidgets('increment button fires callback', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          PosterCard(
            item: mockItem,
            titleSimpToTrad: false,
            onTap: () {},
            onIncrement: () => tapped = true,
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      expect(tapped, isTrue);
    });

    testWidgets('selected renders without crash', (tester) async {
      await tester.pumpWidget(
        wrap(
          PosterCard(
            item: mockItem,
            titleSimpToTrad: false,
            selected: true,
            onTap: () {},
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Anime'), findsOneWidget);
      expect(find.text('6/12 集'), findsOneWidget);
    });
  });
}
