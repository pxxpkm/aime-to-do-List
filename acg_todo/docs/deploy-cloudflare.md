# Deploy ACG To-Do on Cloudflare (Free) — Path A + B

Static **Flutter Web** on **Pages** + **Pages Function** `/proxy` for Bangumi images.

## What you get

| Piece | Role |
|-------|------|
| Cloudflare Pages | HTTPS + custom domain + CDN for `build/web` |
| `functions/proxy.js` | Same-origin image proxy (bgm.tv whitelist only) |
| Browser Hive | Library data when `/api/health` is absent |
| Local `proxy_server.py` | Optional full SQLite disk library on your PC |

**Not included:** multi-device cloud DB (that is path C / Supabase or D1).

## Prerequisites

1. Cloudflare account, domain **Active** on Cloudflare DNS  
2. Flutter stable, `flutter build web` works  
3. Node.js 18+ (for `wrangler`, optional)  
4. Export a JSON backup from local 8080 first  

## 1. Build

```bash
cd acg_todo
flutter pub get
flutter test
flutter build web --release --base-href /
```

`web/_redirects`, `_headers`, `robots.txt` are copied into `build/web/`.

## 2. Deploy (recommended: Wrangler direct upload)

From `acg_todo` (so `functions/` is next to the project):

```bash
# first time
npx wrangler login

# create project once in dashboard or:
npx wrangler pages project create acg-todo

# deploy static assets + Pages Functions
npx wrangler pages deploy build/web --project-name=acg-todo
```

Confirm Function:  
`https://<project>.pages.dev/proxy?url=https%3A%2F%2Flain.bgm.tv%2F...`  
- bad host → 403  
- good host → image bytes  

## 3. Custom domain

1. Pages → project → **Custom domains** → `todo.yourdomain.com`  
2. Wait until **Active** (SSL automatic)  
3. Optional: Always Use HTTPS in SSL/TLS  

## 4. Git-connected deploys (optional)

| Field | Value |
|-------|--------|
| Root directory | `acg_todo` |
| Build command | (install Flutter then) `flutter build web --release --base-href /` |
| Build output | `build/web` |

Pages Functions under `acg_todo/functions/` deploy with the project.

Flutter on CI is fragile; many people **build locally** and only use Wrangler upload.

## 5. After deploy — checklist

- [ ] Open `https://todo.yourdomain.com`  
- [ ] Banner says **瀏覽器儲存** (not 8080) on the public host  
- [ ] Add an item, refresh — still there  
- [ ] Deep link `/library` refresh works (SPA `_redirects`)  
- [ ] Posters load (via `/proxy`)  
- [ ] Settings → export backup  
- [ ] `robots.txt` is `Disallow: /`  

## 6. Local disk library still works

```bash
flutter build web --release
python proxy_server.py
# http://127.0.0.1:8080
```

Same-origin `/proxy` and `/api/*` on 8080; Flutter uses `Uri.base.origin` for poster proxy.

## 7. Security notes (short)

- Proxy **only** allows `*.bgm.tv` — do not widen without review  
- Do not upload `data/library.db` or tokens to git/Pages  
- Public URL + Hive = personal data in that browser; export often  
- Prefer not listing the site on search engines (`noindex` + robots)  
- Never expose home `proxy_server.py` to the internet without auth  

## 8. Troubleshooting

| Symptom | Fix |
|---------|-----|
| 404 on `/library` refresh | Ensure `_redirects` in deploy output |
| Broken Bangumi posters | Check `/proxy` Function logs; host whitelist |
| Empty library after clear site | Expected for Hive — restore JSON import |
| Old UI after deploy | Settings → 強制重新載入; hard refresh |

## 9. Next steps (not in A+B)

- Cloudflare Access (lock site to your email)  
- Path C: Supabase / D1 for multi-device sync  
