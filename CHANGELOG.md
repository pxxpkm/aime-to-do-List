# Changelog

## 1.0.0 — 2026-07-10

First formal baseline (`git tag v1.0.0`, `pubspec` `1.0.0+1`).

### Features
- Bangumi + AniList search/add; manual entry; poster wall (Web CORS proxy)
- Progress, deadlines, reminders, folders (incl. system「已完成」)
- Multi-period goals (day / rolling / month / year)
- Home: type/folder/tag filters, sort modes, multi-select delete
- Personal `userScore` (0–10 step 0.1); free tags; item editor
- Site score (BGM/AniList) read-only
- Local Hive; optional Supabase/Firebase init only

### Known limits
- Sort drag only in **手動** + folder/uncategorized view
- Auto sort on「全部」uses flat poster wall
- No cloud sync for items; FCM/Edge not deployed
