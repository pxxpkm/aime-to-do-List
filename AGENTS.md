# AGENTS.md — ACG To-Do List

## Overview

Cross-platform backlog tracker for Anime, Manga, Light Novels, and Games.
Users add items from AniList search (or manually), track progress against
deadlines, and receive push notifications when action is needed.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart), targeting iOS & Android |
| State Management | Riverpod (AsyncNotifier, Notifier) |
| Backend | Supabase (Auth + PostgreSQL + Storage + Edge Functions) |
| External API | AniList GraphQL (free, 90 req/min, no key required) |
| Local Storage | Hive (offline cache) |
| Push Notifications | Firebase Cloud Messaging + Supabase Edge Functions |
| Routing | go_router |
| UI Charts | fl_chart |
| Code Generation | freezed, json_serializable, riverpod_generator |

## Data Sources

| Category | API | Type / Param |
|----------|-----|--------------|
| Anime | AniList GraphQL | `type: ANIME` |
| Manga | AniList GraphQL | `type: MANGA` |
| Light Novel | AniList GraphQL | `type: NOVEL` |
| Game | Manual entry (or RAWG) | — |
| Fallback | Manual entry | Upload poster + metadata |

If AniList search returns no results for a light novel, **always offer
manual entry**. Never block the user flow behind API availability.

## Database Schema (Supabase)

```sql
CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE NOT NULL,
  display_name text,
  avatar_url text,
  fcm_token text,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  type text NOT NULL CHECK (type IN ('anime','manga','light_novel','game')),
  anilist_id int,
  title text NOT NULL,
  poster_url text,
  total_units int,
  current_units int DEFAULT 0,
  unit_label text DEFAULT '集',
  status text DEFAULT 'in_progress'
    CHECK (status IN ('in_progress','completed','paused','dropped')),
  deadline timestamptz,
  created_at timestamptz DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE milestones (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid REFERENCES items(id) ON DELETE CASCADE,
  label text NOT NULL,
  percentage int NOT NULL,
  completed boolean DEFAULT false
);

CREATE TABLE notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id uuid REFERENCES items(id) ON DELETE CASCADE,
  type text NOT NULL,
  scheduled_at timestamptz NOT NULL,
  sent_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Row Level Security: users can only access their own data
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY items_owner ON items
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY milestones_owner ON milestones
  FOR ALL USING (item_id IN (SELECT id FROM items WHERE auth.uid() = user_id));
CREATE POLICY notifications_owner ON notifications
  FOR ALL USING (item_id IN (SELECT id FROM items WHERE auth.uid() = user_id));
```

## UI / Theme

- **Default: dark theme only for v1**
- Background: gradient `#1a1a2e` → `#16213e`
- Surface cards: `#0f3460` at 80% opacity + backdrop blur (glassmorphism)
- Category accent colors:
  - Anime: `#e94560`
  - Manga: `#0fb5d4`
  - Light Novel: `#f5a623`
  - Game: `#9b59b6`
- Typography: bold display font for headers, clean sans for body

## Project Structure

```
lib/
├── main.dart                  # Entry point, init Hive + Supabase + Firebase
├── app.dart                   # MaterialApp.router + theme
├── core/
│   ├── theme/
│   │   ├── app_colors.dart    # Category + semantic color tokens
│   │   ├── app_theme.dart     # Dark ThemeData
│   │   └── app_typography.dart
│   ├── router/
│   │   └── app_router.dart    # go_router config
│   └── utils/
│       ├── logger.dart        # Centralized logger wrapper
│       └── date_utils.dart    # Deadline calculations
├── data/
│   ├── models/
│   │   ├── item_model.dart    # freezed + Supabase JSON
│   │   ├── milestone_model.dart
│   │   └── notification_model.dart
│   ├── repositories/
│   │   ├── items_repository.dart       # CRUD + sync
│   │   ├── anilist/
│   │   │   ├── anilist_client.dart     # GraphQL client + rate limiter
│   │   │   ├── queries.dart            # GraphQL query strings
│   │   │   └── mappers.dart            # DTO → domain entity
│   │   └── local/
│   │       ├── hive_cache.dart         # Box management
│   │       └── item_local_cache.dart   # Local CRUD + sync queue
├── domain/
│   ├── entities/
│   │   ├── item.dart
│   │   ├── milestone.dart
│   │   └── notification.dart
│   └── services/
│       ├── deadline_service.dart       # Days remaining, risk classification
│       └── notification_scheduler.dart # FCM token + Edge Function trigger
├── presentation/
│   ├── pages/
│   │   ├── home_page.dart
│   │   ├── search_page.dart
│   │   ├── manual_entry_page.dart
│   │   ├── item_detail_page.dart
│   │   ├── stats_page.dart
│   │   ├── notifications_page.dart
│   │   └── settings_page.dart
│   ├── widgets/
│   │   ├── poster_card.dart
│   │   ├── progress_ring.dart
│   │   ├── deadline_badge.dart
│   │   ├── category_chip.dart
│   │   ├── glass_card.dart
│   │   └── shimmer_placeholder.dart
│   └── providers/
│       ├── items_provider.dart
│       ├── search_provider.dart
│       └── user_provider.dart
└── l10n/
    ├── app_en.arb
    └── app_zh.arb
```

## Key Commands

```bash
flutter run                                  # run on connected device
flutter test                                 # unit + widget tests
flutter test --coverage                      # with coverage
flutter build apk --release                  # Android APK
flutter build appbundle --release            # Android AAB
flutter build ios --release                  # iOS (requires signing)
dart run build_runner build --delete-conflicting-outputs   # code gen
dart run build_runner watch                  # watch mode
```

## Supabase Edge Functions

```bash
supabase functions new notify-deadline      # scaffold
supabase functions serve --env-file .env.local   # local dev
supabase functions deploy notify-deadline   # deploy
```

## Conventions

- **Repository pattern mandatory** — all data access through `Repository`
  classes. Never call Supabase or AniList directly from widgets.
- **Riverpod first** — `AsyncNotifier` for async, `Notifier` for sync state.
- **Freezed models** — all data classes use `freezed` + `json_serializable`.
- **Local-first architecture** — Hive cache always has data before network
  call completes. Supabase sync happens in background.
- **GraphQL queries centralized** — all AniList queries in `queries.dart`,
  never inline in widgets.
- **Image handling** — `cached_network_image` for URLs, `image_picker` for
  uploads to Supabase Storage.
- **No print/debugPrint in production** — use `Logger` from `core/utils`.
- **Hero animations** use item `id.toString()` as tag.
- **Testing**: every repository gets a test; mock HTTP with `mocktail`.

## AniList API Reference

- Endpoint: `POST https://graphql.anilist.co`
- Rate limit: 90 req/minute — implement token bucket rate limiter
- Light Novel type: `NOVEL` (not `MANGO` or `ANIME`)
- Cover image sizes available: `large`, `extraLarge`, `medium`
- Missing fields in NOVEL response are common — handle nulls defensively

## FCM & Notifications

- FCM token stored in `users.fcm_token` on app start and on refresh
- Edge Function `notify-deadline` triggered by `pg_cron` daily at 09:00
- Notification types:
  - `deadline_3day` — 3 days before deadline
  - `deadline_1day` — 1 day before deadline
  - `stale_7day` — 7+ days since last progress update
- Foreground → `flutter_local_notifications` banner
- Background → system notification, tap → deep link to item

## Testing Strategy

- **Unit tests**: models, rate limiter, deadline calculations
- **Widget tests**: PosterCard, ProgressRing, DeadlineBadge
- **Integration tests**: full add → update → complete flow with Supabase
  emulator
- Run `flutter test --coverage` and aim for > 70% on data + domain layers

## Do Not

- Do not hardcode AniList credentials (even though none required today)
- Do not call AniList from main thread consistently — wrap in repository
- Do not trigger FCM from client — always via Edge Function
- Do not access Supabase client directly in widgets — go through provider
- Do not use `print()` or `debugPrint()` — use `Logger`
- Do not block user flow on API availability — offline mode is a feature
