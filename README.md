# ACG To-Do

Cross-platform backlog tracker for Anime / Manga / Light Novel / Game.  
**Formal baseline: v1.0.0** (see `CHANGELOG.md`, `git tag v1.0.0`).

## Layout

| Path | Role |
|------|------|
| `acg_todo/` | Flutter app |
| `HANDOFF.md` | Session handoff / source of truth for “what we built” |
| `AGENTS.md` | Agent conventions (may describe future backend) |
| `CHANGELOG.md` | Release notes |

## Run (Web)

```bash
cd acg_todo
flutter pub get
flutter build web --release
python proxy_server.py
# open http://127.0.0.1:8080
```

Do **not** use plain `python -m http.server` if you need Bangumi posters (CORS).

## Tests

```bash
cd acg_todo
flutter test
```

## Version control (quick)

```bash
# New work
git switch main
git switch -c feature/short-name

# Save
git add -A
git commit -m "describe change"

# Back to formal 1.0 (destroys uncommitted work on main)
git switch main
git reset --hard v1.0.0
```

Details: `HANDOFF.md` → section **版本控制**.
