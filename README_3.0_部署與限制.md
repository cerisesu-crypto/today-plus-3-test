# TODAY+ 3.0 測試版

本資料夾由 TODAY+ 2.1 六個檔案複製而來；原始 2.1 資料夾未修改。3.0 加入 Google 登入與 Supabase `tasks` 雲端同步。分類、優先順序、日期、時段、備註等舊版專屬資料存於 `tasks.app_data` JSON 欄位：

- `id` → Supabase UUID；新建任務用 UUID，舊版字串 ID 在首次雲端同步時轉成 UUID
- `title` → `title`
- 日期／時段／小時 → `due_date`、`time_period`、`due_hour`
- 分類／優先順序／完成狀態 → `category`、`priority`、`is_completed`
- 備註 → `description` 及 `app_data.note`
- Google Calendar 欄位由此版本保留，不由任務同步覆寫

## 部署步驟

1. 在 Supabase SQL Editor 執行 `migrations/202611120002_today_plus_app_data.sql`。此遷移依照已核對的 `tasks` 欄位清單，只新增 `app_data` JSON 欄位，不重建資料表或更改現有 RLS。
2. 確認 Google provider 已啟用，Supabase URL Configuration 的 Redirect URLs 允許測試網址。正式 Site URL 保持 `https://cerisesu-crypto.github.io/today-plus/`。
3. 將本資料夾內容放入**新的 GitHub repository**（例如 `today-plus-3-test`），啟用該 repository 的 GitHub Pages。不要推送到正式 TODAY+ repository 的 Pages 來源或替換其中 2.1 檔案。
4. 取得新測試站網址後，將它加入 Supabase Auth Redirect URLs。`config.js` 已填 Supabase URL 和 publishable key；publishable key 可放在瀏覽器端。不得加入 Google Client Secret、refresh token 或 `service_role`。
5. 開啟測試站，使用 Google 登入，新增、修改、完成、刪除測試任務，重新整理並於另一個已登入瀏覽器查看資料。確認 RLS 僅允許 `user_id = auth.uid()`。

## 尚未驗證／未實作

程式已接入 Google OAuth 登入與 `tasks` CRUD，同步仍未在部署環境驗證。初次登入會合併本機與雲端任務；相同 ID 時保留雲端版本。刪除會呼叫 Supabase 刪除 API；離線刪除不會排隊，且登入前刪除不會自動同步到雲端。

Google Calendar 雙向同步未實作。目前登入流程沒有要求 Calendar scopes，也沒有安全的 server-side refresh-token 流程。最少下一步：在 Google Cloud 啟用 Calendar API，另建受登入 JWT 保護的 Supabase Edge Function OAuth 授權碼流程，要求 `https://www.googleapis.com/auth/calendar.events`（讀寫事件）及 `https://www.googleapis.com/auth/calendar.calendarlist.readonly`（列出使用者訂閱的日曆），並帶 `access_type=offline`；將 refresh token 安全存於 Vault，再由函式負責日曆同步。Google 只有在離線授權下才提供 refresh token，Supabase Auth 也不會替應用自動刷新 Google provider token；不要把 Google access/refresh token 放進前端。
