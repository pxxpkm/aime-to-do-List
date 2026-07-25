# AGENTS.md — ACG To-Do List

## Overview

Cross-platform backlog tracker for Anime, Manga, Light Novels, and Games.
Primary target: **Flutter Web** with optional local SQLite via `proxy_server.py`.
Users add items from Bangumi / AniList search (or manually), track progress
against deadlines, and manage goals / pins / folders.

> **Truth source**: this file + `HANDOFF.md` + `lib/`.  
> Do not assume legacy “dark-only + full Supabase items cloud” — that is outdated.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.x (Dart), **Web first** (+ iOS/Android capable) |
| State Management | Riverpod (`Notifier` / `@riverpod` codegen) |
| Local library | **SQLite** via `python proxy_server.py` (preferred) or **Hive** fallback |
| Settings / goals | `GoalSettingsStore` (Hive or server settings bundle) |
| External API | **Bangumi** (primary) + **AniList GraphQL** (secondary) |
| Metadata search | `SourceRegistry` + `MediaSourceAdapter` (`lib/data/metadata/`) |
| Routing | go_router |
| UI | Paper light theme (`AppColors` / `AppTheme`) |
| Charts | fl_chart |
| Code generation | freezed, json_serializable, riverpod_generator |

## Data Sources

| Category | Adapter key | Notes |
|----------|-------------|--------|
| Anime | bangumi / anilist | Both supported |
| Manga | bangumi / anilist | Both supported |
| Light Novel | bangumi / anilist | Bangumi type book; AniList NOVEL |
| Game | bangumi | AniList **not** supported |
| Fallback | manual entry | Never block on API |

Search returns neutral **`SourceCandidate`**. UI uses **`SearchFacade`**
(`search_facade.dart`); do not hardcode Bangumi/AniList branches in pages.

## Storage modes

| Mode | When | Persistence |
|------|------|-------------|
| **Server (SQLite)** | `/api/health` OK on same origin (typically `http://127.0.0.1:8080`) | `acg_todo/data/library.db` |
| **Hive** | probe fails (`flutter run` random port, no proxy) | Browser IndexedDB — clear site may wipe library |

Items **do not** write to Supabase. Cloud auth/FCM is optional shell only.

## Formal run (disk library)

```bash
cd acg_todo
flutter build web
python proxy_server.py
# open only http://127.0.0.1:8080
```

After UI changes, **rebuild web** or use Settings → 強制重新載入 (clears SW/cache).

## Project structure (high level)

```
lib/
├── main.dart                 # Hive init, probe server, ProviderScope overrides
├── data/
│   ├── metadata/             # SourceCandidate, adapters, SourceRegistry
│   ├── local/                # LibraryStore, GoalSettings, BangumiToken, notif
│   └── repositories/         # items, folders, bangumi, anilist, backup
├── domain/entities|services
└── presentation/
    ├── pages/                # dashboard, library, search, detail, settings…
    ├── providers/            # items (incremental patch), search_facade, …
    └── widgets/
```

## Architecture rules

1. **Repository pattern** — no Supabase/AniList/Bangumi calls from widgets.
2. **Riverpod** — list mutations go through `ItemsNotifier` (prefer **patch by id**, full refresh only for reorder / pin reindex / bulk).
3. **Metadata adapters** — new sources: implement `MediaSourceAdapter`, register in `sourceRegistryProvider`.
4. **Theme** — `AppColors` only; paper light is default (`AppTheme.dark` aliases light).
5. **Logging** — `Logger`, never `print` in production paths.
6. **Hero** — session browse does not change pin tiers; `pinHomeHero` is settings-only.

## Key product surfaces

| Surface | Notes |
|---------|--------|
| Home hero | Immersive 2:3; arrows / swipe / keyboard; gacha dialog |
| 接下來 | Continue strip + stale/risk badges |
| Library | Poster wall, fit cover/contain, `/` `Esc` `Ctrl+A` |
| Detail | Wide ≥900 split; narrow stack |
| Settings | Backup, Bangumi token disk opt-in, hard reload |

## Testing

```bash
cd acg_todo
flutter test
flutter analyze
```

Unit-test pure helpers (pool, badges, registry, patch). Mock HTTP with mocktail where needed.

## Do not

- Do not treat AGENTS “dark-only Supabase items” as current product
- Do not call AniList/Bangumi from widgets
- Do not `setPinTier` from gacha / hero browse
- Do not skip `flutter build web` when verifying on 8080
- Do not put secrets in source; Bangumi token opt-in disk is user-controlled
