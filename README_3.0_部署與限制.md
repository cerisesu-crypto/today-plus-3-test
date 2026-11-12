# TODAY+ 3.0 測試版

3.0 是獨立測試站；TODAY+ 2.1 原版未覆蓋。使用 Google OAuth 登入，任務存在 Supabase `tasks`，每次只查詢登入者的 `user_id`。資料欄位對照：日期／時段／小時→`due_date`／`time_period`／`due_hour`；分鐘和舊版備註→`app_data`；優先順序轉成資料庫使用的「高／一般／低」。Google Calendar 雙向同步尚未實作。

## 跨裝置測試步驟

1. 手機與筆電開啟同一個測試網址，使用同一個 Google 帳號登入。若任務仍不一致，請確認兩個登入 session 的 Supabase user UUID 相同。
2. 手機新增一筆專用測試任務，等狀態顯示「已同步到雲端」。
3. 筆電重新整理，確認同一任務出現且同步狀態成功。程式依登入者 UUID 查詢 `tasks`；若同 ID 的雲端資料存在，以雲端版本為準，本機資料不會蓋過它。
4. 在任一裝置編輯測試任務或切換完成狀態，等同步成功後，在另一裝置重新整理確認更新。
5. 刪除專用測試任務，等刪除完成後到另一裝置重新整理，確認任務消失。刪除使用 `app_data.deleted` 軟刪除標記，不會永久移除資料列。
6. 若狀態顯示同步失敗或讀取失敗，資料仍保留在本機；恢復網路後重新整理或再操作一次重試。只有雲端寫入成功並讀回後才顯示同步成功。

## 部署與安全

- 測試站：https://cerisesu-crypto.github.io/today-plus-3-test/
- Supabase Redirect URLs 必須允許以上完整網址；正式 Site URL 保持 `https://cerisesu-crypto.github.io/today-plus/`。
- 瀏覽器端只放 Supabase URL 和 publishable key。Google Client Secret、refresh token、`service_role` 不可放入前端。
- `tasks` 的 RLS 應限制 `user_id = auth.uid()`。

## Google Calendar 後續

目前登入未要求 Calendar 權限。後續需啟用 Google Calendar API，採用受使用者登入 JWT 保護的 Supabase Edge Function 處理 Google OAuth 授權碼及 token refresh；refresh token 必須安全存於伺服器端，例如 Vault。前端不可持有 Google Client Secret 或 refresh token。
