# HANDOFF.md — ACG To-Do（給下一個零上下文會話）

> **最後更新**：2026-07-25（Phase B1+B2：Hero 導覽 + 接下來強化 + gacha 放大）  
> **專案路徑**：`C:\todo\acg_todo\` · **Git root**：`C:\todo`  
> **Flutter**：3.x · Dart 3.x · 以 **Flutter Web** 為主  
> **文件優先**：本 HANDOFF + `lib/` 真相；`AGENTS.md` 有過時（舊 dark/Supabase 全量）部分

---

## 0. 30 秒摘要（新會話先讀）

1. **產品**：ACG backlog（Anime/Manga/LN/Game）— 搜尋加入、進度、限期、目標、釘選、統計。  
2. **正式跑法（磁碟庫，清瀏覽器不丟作品/目標）**：
   ```bash
   cd C:\todo\acg_todo
   flutter build web
   python proxy_server.py
   # 只開 http://127.0.0.1:8080
   ```
   - DB：`acg_todo/data/library.db`（gitignore）  
    - Bangumi token **仍在 Hive**；通知在 **server 模式上 SQLite**（Hive 降級仍用 IndexedDB）  
3. **剛做完**：主頁**沉浸大海報**（近全寬/近一屏高 2:3）+ **今日進度角標**（點開 sheet 重設）；「接下來」橫滑；側欄；媒體庫海報牆；SQLite。  
4. **Git**：大量改動可能仍未 commit（本機若無 `user.name`/`user.email` 會 commit 失敗）。勿自動改 git config。  
5. **測試**：`cd acg_todo && flutter test` 應全綠。

---

## 1. 我們在做什麼任務

### 本會話主線（按時間）
| 主題 | 狀態 |
|------|------|
| 字重/墨色（Noto 偏幼） | ✅ typography w700 + 墨色加深 |
| ReinaManager 對照改善 | 文件/路線；部分已落地 |
| 四 tab Shell | ✅ 後改為**側欄** |
| 匯出/匯入 JSON | ✅ 設定 → 資料 |
| 本機 8080 + SQLite（S1–S2） | ✅ items/folders/goals 上磁碟 |
| S3.1 batch + S3.2 Hive→磁碟遷移 | ✅ |
| 主頁/媒體庫拆分 + 側欄 | ✅ |
| 媒體庫 poster 密度 + 響應式欄 | ✅ |
| 主頁 Hero + 抽海報小遊戲 | ✅ |
| 主頁重整（大海報主調、目標重設、不寡） | ✅ **本會話最後執行** |

### 產品定位（別跑偏）
- **不是** ReinaManager 啟動器/存檔備份  
- **是** 進度 backlog + 畫廊式 UI  
- 雲端 Supabase/FCM：**optional 殼**，items **不寫雲**

---

## 2. 已經完成什麼（關鍵能力 + 路徑）

### 2.1 導航 Shell
- **寬 ≥800**：左側 `NavigationRail`  
- **窄**：頂部漢堡 + `Drawer`  
- **無底欄**  
- 檔案：`lib/presentation/shell/app_shell.dart`  
- 路由：`lib/core/router/app_router.dart`  
  - `/` → `DashboardPage`  
  - `/library` → `LibraryPage`（海報牆）  
   - `/collection` → `CollectionPage`（資料夾總覽）  
   - `/library?folder=` → 媒體庫篩選（`none`=未分類）  
  - `/settings` → 設定  
  - 全螢幕：`/search`, `/item/:id`, `/stats`, `/notifications`, `/pin/:tier` …

### 2.2 主頁（Dashboard）— 沉浸海報
- 檔案：  
  - `lib/presentation/pages/dashboard_page.dart`  
  - `lib/presentation/widgets/home_hero_stage.dart`  
  - `lib/presentation/widgets/home_goal_card.dart`（`HomeGoalPill` + `showHomeGoalSheet`）  
  - `lib/presentation/widgets/poster_gacha_dialog.dart`  
  - `lib/presentation/widgets/continue_strip.dart`  
- 結構：
  1. **沉浸大海報**（2:3；近全寬；高約可用區 92%；**無 400 寬上限**）  
  2. 圖上疊：左上 **今日進度 pill**、右上通知、**左右箭嘴**切換海報池、底標題/進度（含 `n/m`）、**抽海報 / 開啟 / +1**  
  3. **接下來** 橫滑（最近進度 + 補 pin）；pin chip → `/pin/...`  
  4. **沒有** 獨立「今日進度」大卡、沒有雙欄 pin 板  
- 點 pill → bottom sheet（完整目標 + **重設今日**）  
- **海報導覽**：箭嘴 / 水平滑動 / 鍵盤 ←→ 在 `buildHeroPool` 循環；**只改 session**，不寫 pinTier  
- **固定鈕**：主頁 CTA「固定/已固定」→ `pinHomeHero` / 改回 `daily`；長按海報 → 全螢幕  
- 抽海報：彈窗、**不改 pinTier/進度**；2:3 高度優先、桌面寬可至 **~640**；可「設為主頁海報」  
- **接下來**：strip 寬 128、高 220；`久未動`（staleDays）+ 期限 risk 邊框/左色條；`continue_item_badges.dart`  
- 目標重設：`GoalSettingsStore.setTodayProgress(0)`，**只清今日**，確認 dialog  
- 純函式：`home_hero_pool.dart`、`continue_item_badges.dart`  

### 2.3 項目詳情（ItemDetail）
- `lib/presentation/pages/item_detail_page.dart` + `detail_layout.dart`  
- **寬 ≥900（16:9）左右分割**：  
  - 左海報：`detailWidePosterSize` — **高度優先**吃滿可用高，2:3  
  - 右資訊：`maxWidth: 460`，**頂對齊**，不拉滿剩餘寬  
  - 整組 `Row` 水平置中；完成鈕在右欄底 sticky  
- **窄：上下分割** — `detailHeroPosterSize` + 資訊 `maxWidth: 720` 居中 + 底欄完成  
- **進度卡橫排**；Header chips；詳情紙卡（簡介/標籤/備註/管理 grid）  
- **編輯入口**：只 AppBar「編輯」  
- 簡介可折疊（預設 3 行）  

### 2.4 媒體庫
- `lib/presentation/pages/library_page.dart`  
- `PosterCardDensity.poster`（全圖 + 底漸層字）  
- 排序：`HomeSortMode` + **升序/降序**（`homeSortAscending`；手動模式除外）  
- 欄數：`home_layout.dart` 的 minCardWidth（畫廊/標準/緊湊）  
- 圓角較小（poster ~8）  

### 2.4b 統計
- `stats_page.dart`：庫存 summary + **目標進度**（今日/滾動/月/年）+ 重設  
- 重設只清 `progressDays` 累計，**不改作品集數**  
- 近 14 日 bar 用真實 day buckets  

### 2.5 本機 SQLite API
- 入口：`python proxy_server.py`（`acg_todo/proxy_server.py`）  
- 實作：`server/db.py`, `server/api.py`  
- 重點 endpoint：  
  - `GET /api/health`  
  - `GET/PUT /api/v1/library`  
  - `PUT/DELETE /api/v1/items/{id}`  
  - `PUT /api/v1/items:batch`  
  - `PUT /api/v1/folders:batch`  
  - `GET/PUT /api/v1/settings`  
- Flutter：  
  - `LibraryStore` / `HiveLibraryStore` / `ServerLibraryStore`  
  - `main.dart`：`probeLibraryServer` → server 或 Hive 降級  
  - goals：`GoalSettingsStore.hive` / `.server`  

### 2.6 備份 / 遷移
- 匯出匯入 JSON：設定 → 資料  
- Hive→磁碟：server 模式「上傳瀏覽器資料到磁碟庫」  
- `library_backup_service.dart` merge 規則（id / anilist / bgm、進度 max）  

### 2.7 UI 主題
- Paper light：`app_colors.dart`, `app_theme.dart`, `app_typography.dart`（Noto TC，字重已加粗）  
- **預設 dark 已廢棄**（`AppTheme.dark => light`）  

---

## 3. 目前卡在哪 / 未完成

| 項目 | 狀態 |
|------|------|
| **Git commit** | 里程碑已 commit（paper + shell + sqlite + home/detail + collection + notif） |
| **收藏頁** | ✅ 資料夾網格 → `/library?folder=` |
| **S3.3 通知上 SQLite** | ✅ 事件表 + prefs 進 settings.bundle；Hive 可遷移 |
| **S3.4 Bangumi token 上磁碟** | 未做（預設應 opt-in） |
| **主頁 pin 雙欄 board** | **有意拿掉**（改 chip + 接下來）；若用戶要回雙欄需還原 |
| **AGENTS.md** | 仍寫 dark / 全量 Supabase，勿當真相 |
| **工作區是否已 `flutter build web`** | 改 UI 後若走 8080 **必須 rebuild** 才看得到 |

### 最近意圖（已執行）
- 海報盡量沉浸（首屏幾乎全給 poster）  
- 今日進度改角標，詳情/重設進 sheet  
- 主頁：海報 → 接下來  

---

## 4. 下一步計畫（給新會話）

### 優先建議 A — 穩固
1. 設定 git identity 後 **commit** 里程碑（paper + shell + sqlite + immersive home）  
2. `flutter build web` + 重啟 `proxy_server.py`，用戶驗收沉浸海報 + pill  
3. 依反饋微調：pill 位置、高度比例、pin chip 是否要回 board  

### 優先建議 B — 產品
1. ~~收藏真頁~~ ✅  
2. ~~S3.3 通知進 SQLite~~ ✅  
3. 媒體庫細節（fit contain 選項等） / Bangumi token 上磁碟（opt-in）  

### 優先建議 C — 架構（Reina 對照，非急）
- Metadata adapter 註冊表、ItemsNotifier 增量 patch  

---

## 5. 踩過的坑（絕對不要再踩）

### 資料 / 8080
1. **不同 origin = 不同 Hive**  
   - `127.0.0.1:8080` ≠ `localhost:隨機port`（flutter run）  
   - 清快取後「空庫」常是開錯 port，不是 SQLite 壞了  
2. **正式用只開 8080 + proxy**；`flutter run` 無 API 會 Hive 降級  
3. **改 Flutter 後必須 `flutter build web`** 才更新 proxy 靜態檔  
4. **Service Worker** 會鎖舊 JS：清 Cache + Unregister SW；清站時**別亂勾 IndexedDB** 除非知道後果  
5. **DB 路徑** 必須絕對路徑到 `acg_todo/data/library.db`（proxy 會 `chdir` 到 `build/web`）  
6. **8080 被舊 process 佔用** 會像 API 404：先殺 port 再開 proxy  

### 導航 / UI
7. **雙 Scaffold 底欄曾被蓋住** → 已改側欄；詳情路由必須在 Shell **外**  
8. **直式海報不要用橫幅比例**（`width * 0.48` 高度）→ 只見封面一條；維持 **2:3**  
9. **抽海報不要和主頁 Hero 同塊 rolling** → 必須彈窗；且**禁止 setPinTier**  
10. **Google Fonts** 清快取後可能短暫變細（網路重載）；非資料問題  

### 資料模型 / 合併
11. AniList id 格式是 `al_*`，搜尋去重別只靠 title  
12. Merge 進度用 **max**；folder 同名 remap  
13. 目標重設**只清今日** `setTodayProgress(0)`，別誤清月/年  

### 文件
14. **以 HANDOFF + lib 為準**，AGENTS 過時勿照抄 dark-only  
15. `home_page.dart` 現在是 **export DashboardPage**，邏輯在 `dashboard_page.dart` / `library_page.dart`  

---

## 6. 關鍵指令

```bash
cd C:\todo\acg_todo
flutter test
flutter analyze
flutter build web
python proxy_server.py
# smoke API（proxy 已開）：
powershell -NoProfile -File scripts/smoke_api.ps1
```

---

## 7. 關鍵檔案索引

| 用途 | 路徑 |
|------|------|
| 啟動 / 選 Hive vs Server | `lib/main.dart` |
| 路由 | `lib/core/router/app_router.dart` |
| 側欄 | `lib/presentation/shell/app_shell.dart` |
| 主頁 | `lib/presentation/pages/dashboard_page.dart` |
| 詳情 | `item_detail_page.dart` + `item_detail/detail_layout.dart` |
| 收藏 | `collection_page.dart` → `library?folder=` |
| 媒體庫 | `lib/presentation/pages/library_page.dart` |
| Hero / 抽卡 | `home_hero_stage.dart`, `poster_gacha_dialog.dart`, `home/home_hero_pool.dart` |
| 接下來徽章 | `continue_strip.dart`, `home/continue_item_badges.dart` |
| 目標卡 | `home_goal_card.dart` |
| 海報卡 | `poster_card.dart`（density: magazine/strip/**poster**） |
| 欄數 | `presentation/home/home_layout.dart` |
| SQLite API | `proxy_server.py`, `server/db.py`, `server/api.py`（含 `/api/v1/notifications`） |
| 通知 store | `notification_store.dart`, `hive_notification_store.dart`, `server_notification_store.dart` |
| LibraryStore | `data/local/library_store.dart`, `*_library_store.dart` |
| 備份合併 | `domain/services/library_backup_service.dart` |
| 設定/目標 KV | `data/local/goal_settings_store.dart` |

---

## 8. 給新 Agent 的第一句建議

> 讀完本 HANDOFF §0–§5。先 `git status` 與 `flutter test`。用戶正式環境是 **8080 + library.db**。主頁是**沉浸大海報 + 今日進度角標 + 接下來**；收藏頁與通知上 SQLite 未做。改 UI 後記得 **flutter build web**。不要用 AGENTS 的 dark 主題當現況。

---

*本文件由 2026-07-17 會話結束時寫入，供完全無上下文的下一會話接手。*
