# CLAUDE.md — ACG To-Do List

## Purpose

This document guides AI coding assistants (Claude Code, opencode, Copilot)
working on the ACG To-Do List project. It complements `AGENTS.md` with
actionable editing rules and gotcha awareness.

For architecture, tech stack, and conventions, refer to `AGENTS.md`.

---

## Before You Edit

1. Read the relevant section of `AGENTS.md` for the layer you're working in.
2. Check if a repository/method already exists for the data operation.
3. Match existing file naming: `snake_case.dart`, `PascalCase` classes.
4. Run `dart run build_runner build` after adding `@freezed` or `@riverpod`.

---

## Architecture Flow

When implementing a new feature, follow this order:

```
domain/entity      →  data/repository     →  presentation/provider  →  widget →  page →  test
```

Never skip layers. Never put business logic in widgets.

---

## File Editing Rules

### Repository Pattern
All external data access must go through a `Repository`:

```dart
// ✅ Correct
class ItemsRepository {
  final SupabaseClient _supabase;
  final AniListClient _anilist;
  Future<List<Item>> search(String query, ItemCategory type) async { ... }
}

// ❌ Wrong — calling AniList directly from a widget
final response = await _graphqlClient.query(...); // don't do this in a page
```

### State Management
Use Riverpod with code generation:

```dart
@riverpod
class ItemsNotifier extends _$ItemsNotifier {
  @override
  Future<List<Item>> build() async {
    return ref.watch(itemsRepositoryProvider).getAll();
  }
}
```

Freezed models:
```dart
@freezed
class Item with _$Item {
  const factory Item({
    required String id,
    required String title,
    required ItemCategory type,
    ...
  }) = _Item;
}
```

### GraphQL Queries
All AniList queries live in `lib/data/repositories/anilist/queries.dart`:

```dart
const searchAnime = r'''
  query ($search: String, $type: MediaType) {
    Media(search: $search, type: $type) {
      id
      title { romaji native english }
      coverImage { extraLarge }
      episodes
      chapters
      status
    }
  }
''';
```

Never inline these in other files.

### Theme / Colors
Always reference `AppColors`, never hardcode hex:

```dart
// ✅ Correct
color: AppColors.forCategory(ItemCategory.lightNovel)

// ❌ Wrong
color: Color(0xFFF5A623)
```

### Logging
```dart
// ✅ Correct
Logger().d('Item saved: ${item.id}');

// ❌ Wrong
print('Item saved'); // never use print in production code
```

---

## AniList API Gotchas

- **NOVEL ≠ MANGA**: Light Novels use `MediaType.NOVEL`. Do not conflate.
- **Null-heavy responses**: Novel data often missing `volumes`, `chapters`,
  or even `coverImage`. Your parsing must handle nulls without throwing.
- **Rate limit**: 90 req/minute. The `AnilistClient` has a token bucket
  rate limiter. Don't bypass it.
- **No auth required** for search/metadata queries today. If this changes,
  credential goes in environment variable `ANILIST_TOKEN`, never in code.

---

## Supabase Gotchas

- **RLS is enabled**: Every query filters by `auth.uid()`. Anonymous users
  get a Supabase-generated `auth.uid()` — ensure your app initializes auth
  before data queries.
- **Edge Functions for FCM**: Never call Firebase Admin SDK from Flutter.
  Push scheduling + sending happens in `supabase/functions/notify-deadline/`.
- **Storage bucket**: Posters go to the `posters` bucket. Use storage path
  format: `posters/{user_id}/{item_id}.jpg`.

---

## FCM Gotchas

- **iOS simulator doesn't receive push**. Test on real device.
- **Token refresh**: listen to `FirebaseMessaging.instance.onTokenRefresh`
  and update `users.fcm_token` in Supabase.
- **Foreground notifications**: `flutter_local_notifications` must be
  configured or foreground message won't show banner.
- **Deep link routing**: notification payload includes `item_id`. Use
  `go_router` to navigate to `/item/{item_id}` on tap.

---

## Performance Rules

- Poster wall images use `cached_network_image` with `memCacheWidth` to
  limit memory usage.
- Wrap poster cards in `RepaintBoundary` if painting is expensive.
- Hive writes are async — don't `await` them in the UI thread for
  non-critical updates (queue + batch).
- Profile scroll with Flutter DevTools before declaring feature done.

---

## Testing Rules

- Every repository method gets a unit test.
- Mock external HTTP with `mocktail` or `http_mock_adapter`.
- Widget tests use `pumpWidget` + `expect(find.byType(...), findsOneWidget)`.
- Integration tests run against Supabase emulator, not production.
- Run `flutter test --coverage` before committing if data layer changed.

---

## Common Commands

| Task | Command |
|------|---------|
| Install deps | `flutter pub get` |
| Code generation | `dart run build_runner build --delete-conflicting-outputs` |
| Watch code gen | `dart run build_runner watch` |
| Run all tests | `flutter test` |
| Run with coverage | `flutter test --coverage` |
| Analyze code | `flutter analyze` |
| Format code | `dart format lib/` |
| Serve Edge Functions | `supabase functions serve --env-file .env.local` |

---

## When You're Unsure

1. Check if a similar pattern already exists in the codebase.
2. If adding a feature that touches data, grep for existing repository.
3. If breaking something in domain/presentation, check existing tests.
4. When in doubt, follow the layer order: entity → repository → provider → widget.
