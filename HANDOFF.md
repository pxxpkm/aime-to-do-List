# HANDOFF.md — ACG To-Do List 專案交接

> **最後更新**：2026-07-10（**v1.0.0 正式凍結** + Git）
> **目前狀態**：✅ 正式版 **v1.0.0**；排序/評分/標籤/編輯已落地；tests green
> **Flutter**：3.44.5 (stable) · Dart 3.12.2
> **專案路徑**：`C:\todo\acg_todo\` · **Git root**：`C:\todo`

---

## 版本控制（v1.0.0）

| 項目 | 值 |
|------|-----|
| **Git tag** | `v1.0.0` |
| **pubspec** | `1.0.0+1` |
| **倉庫根** | `C:\todo`（含 `acg_todo/` + 本 HANDOFF） |
| **CHANGELOG** | `C:\todo\CHANGELOG.md` |

### 回滾到正式 1.0（改爛時）

```bash
cd C:\todo
git switch main
git reset --hard v1.0.0
```

⚠️ 會丟掉 **main 上未提交** 的修改。有價值的實驗請先 `git switch -c feature/...` 或先 `commit`。

### 只「查看」1.0、不改 main

```bash
git switch --detach v1.0.0
# 看完回主線：
git switch main
```

### 之後改功能（安全流程）

```bash
git switch main
git switch -c feature/短名
# …改碼、flutter test…
git add -A
git commit -m "說明做了什麼"
git switch main
git merge feature/短名
# 里程碑再 tag，例如 v1.1.0，並升 pubspec + 更新本節
```

### HANDOFF 規則

- 與程式 **同一 Git 倉庫**，每個里程碑更新「最後更新 / 目前狀態」
- 文件矛盾時：**以本 HANDOFF + `acg_todo/lib/` 為準**（`AGENTS.md` 可能偏未來後端）

---

## 0. 給新會話的 30 秒摘要

1. **產品**：ACG 進度追蹤（Anime / Manga / Light Novel / Game），v1 以 Flutter Web + Hive 本地為主
2. **✅ 已完成**：搜尋（Bangumi + AniList）、新增、詳情、進度更新、手動建立、限期、統計、通知中心、設定頁、Onboarding
3. **⚠️ 海報問題根因**：`lain.bgm.tv` 無 CORS + Flutter Web `Image.network` 用 XHR → 被擋；`corsproxy.io` 亦 403（LOG 7.0）
4. **已實作**：方案 I — `proxy_server.py` + `toProxyUrl` → `http://127.0.0.1:8080/proxy?url=`
5. **清晰度**：Bangumi 搜尋/儲存用 `images.large`（`/pic/cover/l/`）；`normalizePosterUrl` 會把 `/c|m|s|g/` 升成 `/l/`（Hive 啟動 repair）
6. **文件矛盾**：`AGENTS.md` / `TODO.md` 仍偏完整後端；**以本 HANDOFF 與 `lib/` 為準**

---

## 1. 我們在做什麼

### 產品
跨平台 ACG backlog tracker：從 Bangumi / AniList 搜尋新增、主頁海報牆、進度、限期、統計、設定（Token + 收藏匯入）。

### 實際技術棧
| 層 | 現實 |
|----|------|
| UI | Flutter Web（未來 iOS/Android） |
| 狀態 | Riverpod（含 generator） |
| 本地 | Hive（items + settings）— local-only，無背景 sync |
| 搜尋 | **Bangumi REST 舊版 GET API**（穩定）+ AniList GraphQL |
| 後端 | Supabase / Firebase **僅 optional init**，items 不寫後端 |
| 推送 | 邏輯殼有；Edge Function / FCM 未部署 |
| Web 海報 | **本機 `proxy_server.py`** 同域代理 Bangumi CDN |

### 關鍵檔案結構
```
lib/
├── main.dart
├── core/utils/poster_url.dart    # normalize (https + large) + toProxyUrl
├── data/local/                   # Hive
├── data/repositories/bangumi/    # BangumiClient, mappers
├── presentation/widgets/
│   └── poster_image_widget.dart  # Web: Image.network(toProxyUrl); IO: CachedNetworkImage
proxy_server.py                   # ⚠️ 合併靜態 + /proxy（取代 python -m http.server）
```

---

## 2. 已完成的項目

### Phase 1–5：基礎 + 核心 + 限期 + UI + 測試 ✅
- 搜尋/新增/詳情/進度/手動建立/限期/統計/設定/Onboarding
- 74 tests green（2026-07-10）；analyze 僅 info（Radio deprecation / unnecessary_underscores）

### Sprint：完成資料夾 + 刪除 + 多目標 ✅
- 系統資料夾 `folder_system_completed` /「已完成」；完成自動移入、`previousFolderId` 可還原
- 主頁選取/批次刪除；completed 不進主牆、只在已完成 tile
- Multi-goal：日 / rolling N / 月 / 年（`GoalSettingsStore` + `MultiGoalService` + `DailyGoalBar`）
- 修復：`items_provider` invalidate `multiGoalProvider`；tests 對齊系統資料夾與 clamp 1–999

### Sprint：編輯 / 評分 / 標籤 / 排序 ✅
- `Item.userScore`（0–10 步 0.1）、`Item.tags`；站點 `score` 唯讀
- 主頁排序 `HomeSortMode`（預設 manual）；僅 manual + 資料夾/未分類可拖動
- **排序修復**：非 manual 時「全部」改平面牆並套用 sort；混合牆僅 manual+全部
- ⋮：改總量、我的評分、編輯項目、資料夾、限期、備註、刪除
- `ItemEditorSheet` / `TagsEditor` / `UserScoreEditor`；詳情標籤與編輯
- 主頁標籤 filter；`GoalSettingsStore.homeSortMode`；`home_item_query.dart`

---

## 3. 海報圖片：根因與現況

### 問題描述

| 頁面 | 舊狀態（無 proxy） | 預期（方案 I） |
|------|-------------------|----------------|
| 搜尋 / 主頁 / 詳情 | fallback icon | 海報 200 顯示 |

### 根因

```
Access to XMLHttpRequest at 'https://lain.bgm.tv/pic/cover/...' from origin 'http://127.0.0.1:8080'
has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
```

1. `lain.bgm.tv` **不給** `Access-Control-Allow-Origin`
2. Flutter Web `Image.network` **永遠 XHR 下載 bytes**（不是 native no-cors `<img>`）
3. 第三方 `corsproxy.io` → **LOG 7.0 全數 403**

### 已嘗試（失敗）

| 嘗試 | 結果 |
|------|------|
| A–G Image.network / HtmlElementView / http.get / SW 清除等 | ❌ CORS 或無效 |
| **H. corsproxy.io** | ❌ 403（LOG 7.0） |
| **I. 本機合併 Proxy** | ✅ 程式已寫；待手動驗圖 |

### 方案 I 實作細節

| 項目 | 內容 |
|------|------|
| Server | `acg_todo/proxy_server.py` — `ThreadingHTTPServer` 8080 |
| 靜態 | document root = `build/web` |
| Proxy | `GET /proxy?url=<encoded>`；allowlist `*.bgm.tv` |
| CORS | 回應加 `Access-Control-Allow-Origin: *` |
| Client | `toProxyUrl` → `http://127.0.0.1:8080/proxy?url=` |
| 呼叫點 | `PosterImageWidget._buildWebNetwork` only（native 不走 proxy） |

---

## 4. 修正計畫狀態

```
方案 H corsproxy.io     ❌ LOG 7.0
方案 I 本機合併 Proxy   ✅ 已實作 → 手動驗收
方案 K fallback         備案（功能可用、無圖）
```

**Prod 注意**：`127.0.0.1` proxy 僅本機 dev；上線需同域 reverse proxy 或僅 native。

---

## 5. 踩過的坑（絕對不要再踩）

### 圖片 / Web CORS

| 禁止 | 原因 |
|------|------|
| `http.get` / data URL 塞 Hive | CORS + IndexedDB 膨脹 |
| `HtmlElementView` + `<img>` 當萬靈丹 | 仍可能 cors 模式失敗 |
| 以為 `Image.network` = native `<img>` | **永遠 XHR 下載 + 解碼** |
| 依賴 public CORS proxy | corsproxy.io 403 |
| 存 `http://lain...` 不 normalize | 307 HSTS；一律 https |
| Proxy 不 allowlist host | SSRF 風險 |
| 用 `python -m http.server` 當主 serve | **無 /proxy**；請用 `proxy_server.py` |

### Bangumi API

- 搜尋：`GET https://api.bgm.tv/search/subject/{keyword}?type={1,2,4}&responseGroup=large&max_results=10`
- type: 1=book, 2=anime, 4=game；LN 與 Manga 同 type 1
- 圖片：`https://lain.bgm.tv/pic/cover/{l|c|m|s|g}/...`

---

## 6. 環境與必要命令

```bash
cd C:\todo\acg_todo
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build web --release
python proxy_server.py
# 瀏覽器 http://127.0.0.1:8080
# （可選）python proxy_server.py --port 8080 --root build/web
```

**不要再**對 `build\web` 單獨跑 `python -m http.server 8080`（沒有 proxy 端點）。

---

## 7. 新會話驗收海報

1. 讀本 HANDOFF §0–§4
2. `flutter build web --release`
3. `python proxy_server.py`
4. Chrome `http://127.0.0.1:8080` → 清 Service Workers + site data + hard reload
5. 搜尋 Bangumi（如「進撃」）
6. Network 應見：
   - `http://127.0.0.1:8080/proxy?url=https%3A%2F%2Flain.bgm.tv%2F...`
   - status **200**，type image
7. 搜尋 / 主頁 / 詳情有海報 → 更新本檔狀態為 ✅
8. 若 502/403：查 proxy stderr、確認 allowlist 與上游 URL

### 單元測試

```bash
flutter test test/unit/poster_url_test.dart
```

---

## 8. 功能狀態速查

| 功能 | 狀態 | 備註 |
|------|------|------|
| Bangumi 搜尋 | ✅ | 舊版 GET API |
| AniList 搜尋 | ✅ | GraphQL |
| 新增 / 詳情 / 進度 | ✅ | |
| 手動建立 | ✅ | |
| 海報顯示 | ✅ | proxy 載入 + large 封面；rebuild 後舊 common 會被升級 |
| 主頁卡片牆 Phase1 | ✅ | 大海報卡、響應式列數、長按拖曳排序、卡片 +1、今日目標欄 |
| 資料夾 Phase2 | ✅ | 新建/改名/刪除、移入移出、全部/未分類/夾篩選；⋮ 選單 |
| 通知 Phase3 | ✅ | 提醒引擎、設定開關、通知中心+1、紅點、Web Notification API |
| Phase4 | ✅ | 可自訂提醒日、作品限期、夾磁貼+拖入、海報大小三檔 |
| Metadata + remark | ✅ | score/summary/airDate/source/url + 使用者備註 |
| 限期 / 通知殼 / 統計 / 設定 / Onboarding | ✅ | |
| 收藏匯入 | ⚠️ | mapping 未對齊 dist.json |
| Supabase / FCM | ❌ | 未接入 |

---

> **參考**：Bangumi API https://bangumi.github.io/api/  
> LOG：`log 6.0 .txt`（CORS 原始）、`log 7.0 .txt`（corsproxy 403）、`log 8.0 .txt`（錯用 http.server → /proxy 404）  
> Proxy：`proxy_server.py`  
> **血淚複盤**：`acg_todo/session/RETRO.md`（為何鬼打牆、源頭 session、防再踩）
