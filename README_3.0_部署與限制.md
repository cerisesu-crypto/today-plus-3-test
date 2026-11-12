# TODAY+ 3.0 測試版

本資料夾由 TODAY+ 2.1 六個檔案複製而來；原始 2.1 資料夾未修改。3.0 加入 Google 登入與 Supabase `tasks` 雲端同步。分類、優先順序、日期、時段、備註等舊版專屬資料存於 `tasks.app_data` JSON 欄位：

- `id` → Supabase UUID；新建任務用 UUID，舊版字串 ID 在首次雲端同步時轉成 UUID
- `title` → `title`
- 日期／時段／小時 → `due_date`、`time_period`、`due_hour`
- 時間選擇提供上午／下午、1–12 小時及 00–59 分鐘；分鐘存於 `app_data.minute`，舊資料未指定分鐘時顯示 `00`
- 分類／優先順序／完成狀態 → `category`、`priority`、`is_completed`；優先順序寫入時轉成資料表值「高／一般／低」，讀回時再轉回應用程式內部值
- 備註 → `description` 及 `app_data.note`
- Google Calendar 欄位由此版本保留，不由任務同步覆寫

## 部署步驟

1. 在 Supabase SQL Editor 執行 `migrations/202611120002_today_plus_app_data.sql`。此遷移依照已核對的 `tasks` 欄位清單，只新增 `app_data` JSON 欄位，不重建資料表或更改現有 RLS。
2. 確認 Google provider 已啟用，Supabase URL Configuration 的 Redirect URLs 允許測試網址。正式 Site URL 保持 `https://cerisesu-crypto.github.io/today-plus/`。要使用即時更新，`public.tasks` 也必須加入 Supabase `supabase_realtime` publication（可在 Database → Publications 開啟，或執行下方 SQL）。
3. 將本資料夾內容放入**新的 GitHub repository**（例如 `today-plus-3-test`），啟用該 repository 的 GitHub Pages。不要推送到正式 TODAY+ repository 的 Pages 來源或替換其中 2.1 檔案。
4. 取得新測試站網址後，將它加入 Supabase Auth Redirect URLs。`config.js` 已填 Supabase URL 和 publishable key；publishable key 可放在瀏覽器端。不得加入 Google Client Secret、refresh token 或 `service_role`。
5. 開啟測試站，使用 Google 登入；確認兩台裝置登入的是同一個 Supabase 使用者（以相同 Google email 登入，必要時在 Supabase Auth 使用者清單比對 UUID）。
6. 手機和筆電都保持測試站開啟、使用同一個帳號。手機新增一筆任務後，筆電應即時出現；編輯或切換完成狀態後，筆電也應即時更新。若沒收到事件，先確認 `tasks` 已加入 Realtime publication；兩台裝置仍可重新整理讀取雲端資料。
7. 刪除專用測試任務後，另一台裝置應即時移除它。3.0 會在 `app_data.deleted` 設軟刪除標記，避免離線裝置的舊副本把刪除的任務復活；資料列保留在資料庫，不做永久刪除。
8. 每次操作都要等狀態完成；只有成功寫入並再次讀回雲端後才顯示「已同步到雲端」。失敗時應顯示「同步失敗，資料仍保存在本機」或讀取失敗訊息。

## 尚未驗證／未實作

程式已接入 Google OAuth 登入、依 `user_id` 篩選的雲端讀取及任務同步。同步只送出變動的單筆任務，不再把整份 localStorage 任務清單批次 upsert。新增使用 insert；修改、完成及刪除先比對雲端版本，再以 `id + user_id + updated_at` 條件更新；刪除使用 `app_data.deleted` 軟刪除標記，避免舊裝置副本復活刪除項目。待同步變更會保存在該使用者的本機佇列，網路恢復時重試。若雲端版本已被其他裝置改動，程式保留衝突草稿並顯示衝突狀態，不宣稱已同步。成功讀回雲端後才更新最後同步時間。Google Calendar 欄位不由任務同步覆寫。

本次在 Supabase Dashboard 確認 `tasks` 有 24 筆資料、RLS 開啟且 SELECT／INSERT／UPDATE／DELETE 政策都使用 `auth.uid() = user_id`，`tasks` 已加入 `supabase_realtime` publication。先前已在同一帳號的兩個保持開啟頁面驗證即時新增、編輯名稱、完成狀態與軟刪除；此程式更新尚未部署到公開測試站，需依下列步驟重新測試。雙裝置即時更新仍依賴 Realtime；離線待送佇列與版本衝突的自動合併尚未在真實網路中斷情境驗證，衝突目前保留草稿並提示，沒有自動覆蓋或合併介面。

### 更新版測試步驟

1. 只更新 `today-plus-3-test` 測試 repository；不要覆蓋正式 TODAY+ 2.1。
2. 等 GitHub Pages 部署完成後，兩台裝置都開測試網址，以相同 Google 帳號登入。
3. 各新增一筆以裝置命名的測試任務，確認另一台裝置出現，且 Supabase `tasks` 的 `user_id` 相同。
4. 在手機修改標題、時間與備註，確認筆電同步；再切換完成狀態，確認另一台同步。
5. 刪除其中一筆，確認兩台都消失；Supabase 資料列應保留且 `app_data.deleted` 為 `true`。
6. 保持任務編輯畫面時，可短暫關閉網路新增一筆，再恢復網路，檢查狀態是否先顯示未同步／失敗，恢復後才顯示同步完成。若發生版本衝突，應看到衝突提示且不應覆蓋雲端資料。
7. 重新整理兩台裝置，確認已同步資料仍存在。完成後刪除測試任務。

目前本機僅完成 JavaScript 語法檢查；尚未把更新版發布至 GitHub Pages，也尚未完成上述更新版的手機／筆電實測。

啟用 `tasks` Realtime 的 SQL（可重複執行）：

```sql
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='tasks') then
    alter publication supabase_realtime add table public.tasks;
  end if;
end $$;
```

Google Calendar 雙向同步未實作。目前登入流程沒有要求 Calendar scopes，也沒有安全的 server-side refresh-token 流程。最少下一步：在 Google Cloud 啟用 Calendar API，另建受登入 JWT 保護的 Supabase Edge Function OAuth 授權碼流程，要求 `https://www.googleapis.com/auth/calendar.events`（讀寫事件）及 `https://www.googleapis.com/auth/calendar.calendarlist.readonly`（列出使用者訂閱的日曆），並帶 `access_type=offline`；將 refresh token 安全存於 Vault，再由函式負責日曆同步。Google 只有在離線授權下才提供 refresh token，Supabase Auth 也不會替應用自動刷新 Google provider token；不要把 Google access/refresh token 放進前端。

