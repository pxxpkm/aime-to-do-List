# ACG To-Do List — Development Roadmap

A cross-platform backlog tracker for Anime, Manga, Light Novels, and Games
with poster display, deadline tracking, and push notifications.

---

## Phase 1: Foundation (Week 1-2)

### 1.1 Project Scaffolding
- [ ] `flutter create acg_todo --org com.acg --platforms ios,android`
- [ ] Folder structure under `lib/`:
  ```
  lib/
  ├── main.dart
  ├── app.dart
  ├── core/
  │   ├── theme/
  │   ├── router/
  │   └── utils/
  ├── data/
  │   ├── models/
  │   ├── repositories/
  │   └── local/
  ├── domain/
  │   ├── entities/
  │   └── services/
  ├── presentation/
  │   ├── pages/
  │   ├── widgets/
  │   └── providers/
  └── l10n/
  ```
- [ ] Add dependencies to `pubspec.yaml`:
  - `flutter_riverpod`, `riverpod_annotation`
  - `go_router`
  - `supabase_flutter`
  - `hive`, `hive_flutter`
  - `cached_network_image`
  - `graphql` (AniList client)
  - `firebase_core`, `firebase_messaging`
  - `flutter_local_notifications`
  - `intl`
  - `confetti`
  - `logger`
  - `freezed`, `json_annotation` (dev)

### 1.2 Supabase Backend
- [ ] Create Supabase project at supabase.com
- [ ] Run schema migration:
  ```sql
  CREATE TABLE users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email text UNIQUE NOT NULL,
    display_name text,
    avatar_url text,
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
    status text DEFAULT 'in_progress',
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
    sent_at timestamptz
  );

  -- Enable RLS
  ALTER TABLE items ENABLE ROW LEVEL SECURITY;
  ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
  ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
  ```
- [ ] Enable Storage bucket for poster uploads (`posters`)
- [ ] Configure Auth (Email + anonymous)

### 1.3 AniList API Integration
- [ ] Create `lib/data/repositories/anilist/anilist_client.dart`:
  - GraphQL client pointing to `https://graphql.anilist.co`
  - `searchMedia(type, query)` method
  - `getMediaById(id)` method
  - Rate limiter (90 req/min)
- [ ] Unit tests for query builders

### 1.4 Theme & Design System
- [ ] Define color tokens:
  - Background gradient: `#1a1a2e` → `#16213e`
  - Anime: `#e94560`
  - Manga: `#0fb5d4`
  - Light Novel: `#f5a623`
  - Game: `#9b59b6`
  - Surface: `#0f3460` with 80% opacity + blur
- [ ] Dark `ThemeData` setup
- [ ] Typography tokens (display + body font pairing)
- [ ] Glass card component foundation

---

## Phase 2: Core Features (Week 3-4)

### 2.1 Data Models
- [ ] `Item` model with `freezed` + JSON serialization
- [ ] `Milestone` model
- [ ] `Notification` model
- [ ] `ItemCategory` enum with color/icon mapping

### 2.2 Local Cache (Hive)
- [ ] Register adapters: `ItemAdapter`, `MilestoneAdapter`
- [ ] `LocalCacheRepository` with CRUD
- [ ] Sync strategy: local-first, background remote sync

### 2.3 Poster Card Widget
- [ ] `PosterCard` composable:
  - Poster image with `cached_network_image` + placeholder fallback
  - Progress ring overlay (circular progress)
  - Deadline badge (days remaining)
  - Category color stripe on left edge
- [ ] Hero animation support (`tag: item.id`)

### 2.4 Poster Wall (Home Page)
- [ ] `HomePage` with `GridView.builder` (staggered)
- [ ] Filter chips: All / Anime / Manga / LN / Game
- [ ] Pull-to-refresh sync with AniList
- [ ] Empty state illustration + CTA

### 2.5 Search & Add Flow
- [ ] `SearchPage`:
  - Search bar with debounce
  - Category tabs (Anime / Manga / LN)
  - Results list with poster thumbnails + title + metadata
  - "Can't find it?" → Manual entry form
- [ ] `ManualEntryPage`:
  - Title input
  - Category picker
  - Total units + unit label selector
  - Poster image picker (camera / gallery or URL)
  - Deadline picker
  → Save to Supabase + local cache

### 2.6 Item Detail Page
- [ ] Hero animation from poster card
- [ ] Large poster display
- [ ] Progress section: current / total with +/- controls
  - Slider for batch update
  - Roll-up number animation
- [ ] Deadline section: date picker + countdown
- [ ] Completion flow: mark complete + confetti 🎉

### 2.7 Progress Update
- [ ] `+/-` buttons increment/decrement `current_units`
- [ ] Slider for setting exact value
- [ ] Persist to local → queue background sync to Supabase

---

## Phase 3: Deadlines & Notifications (Week 5-6)

### 3.1 Deadline Engine
- [ ] `DeadlineService`:
  - Calculate days remaining
  - Status classification: `on_track` / `at_risk` / `overdue`
  - Smart estimate: given current pace, will I finish by deadline?
- [ ] `DeadlineBadge` widget showing color-coded countdown

### 3.2 Firebase Cloud Messaging
- [ ] Configure Firebase project for iOS + Android
- [ ] Add `GoogleService-Info.plist` and `google-services.json`
- [ ] FCM token registration in app
- [ ] Token save to `users` table (for targeted push)
- [ ] Foreground message handler (`flutter_local_notifications`)

### 3.3 Scheduled Push (Supabase Edge Function)
- [ ] Create `supabase/functions/notify-deadline/index.ts`:
  - Query items with deadline within next 24h
  - Filter unsent notifications
  - Send FCM push via Firebase Admin SDK
  - Mark notification as sent
- [ ] Schedule via `pg_cron`: `cron.schedule('notify-deadline', '0 9 * * *', ...)`
- [ ] Handle notification types:
  - `deadline_upcoming`: 3 days before
  - `deadline_tomorrow`: 1 day before
  - `stale_progress`: 7+ days no update

### 3.4 Notification Center
- [ ] In-app notification list page
- [ ] Group by type (deadline / stale / other)
- [ ] Deep link tap → item detail

---

## Phase 4: Polish & Delight (Week 7-8)

### 4.1 Visual Polish
- [ ] Glassmorphism card styling with `BackdropFilter`
- [ ] Staggered grid layout for poster wall
- [ ] Smooth page transitions (go_router + custom transitions)
- [ ] Progress ring animation (smooth arc draw)
- [ ] Number roll-up animation on progress change
- [ ] Shimmer loading placeholder for images

### 4.2 Stats Dashboard
- [ ] `StatsPage`:
  - Weekly completion count (bar chart)
  - Category distribution (`fl_chart` pie)
  - Poster timeline (completed items chronological)
  - Heatmap-style activity calendar

### 4.3 Onboarding
- [ ] 3-screen intro: Welcome → Categories → Notifications
- [ ] Request notification permission
- [ ] Skip-friendly (not forced)

### 4.4 Settings
- [ ] `SettingsPage`:
  - Theme toggle (dark only for v1, set up for future light)
  - Notification preferences (opt-in/out per type)
  - Data management (clear cache, export)
  - About / credit AniList

---

## Phase 5: Testing & Release (Week 9-10)

### 5.1 Testing
- [ ] Widget tests:
  - `PosterCard` renders with mock item
  - `DeadlineBadge` shows correct countdown
  - Progress update increments value
- [ ] Integration test:
  - Add item via search → view on poster wall → update progress → mark complete
- [ ] AniList client unit tests (mock HTTP)
- [ ] Supabase emulator for local integration test

### 5.2 Build & Sign
- [ ] iOS:
  - Apple Developer account enrolled
  - Provisioning profile + signing
  - App Store Connect setup
- [ ] Android:
  - Keystore generation
  - App Bundle (AAB) build

### 5.3 Store Assets
- [ ] Screenshots (6.5" + 5.5" iPhone, 10" tablet)
- [ ] Feature graphic
- [ ] App description (EN + ZH-TW)
- [ ] Privacy Policy (Supabase + FCM data usage disclosed)

### 5.4 Submission
- [ ] iOS App Store review submission
- [ ] Google Play Console internal testing track
- [ ] Monitor first-week crashlytics reports

---

## Definition of Done

- [ ] All Phase 1-4 features implemented
- [ ] No `print()` / `debugPrint()` in production code
- [ ] All unit + integration tests passing
- [ ] Lighthouse-style performance: poster wall scrolls at 60fps
- [ ] App builds clean for both platforms
- [ ] Sample data populated for demo

---

## Risk Register

| Risk | Mitigation |
|------|-----------|
| AniList NOVEL coverage < 100% | Manual entry fallback always available |
| FCM iOS delivery issues | Test on real device early (simulator doesn't push) |
| Supabase free tier limits | Monitor usage; local cache reduces reads |
| Flutter rendering perf on old devices | Profile scroll with DevTools, use `RepaintBoundary` |
