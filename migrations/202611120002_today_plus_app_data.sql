-- TODAY+ 3.0 app-specific fields. Apply to the existing TODAY+ 3.0 Supabase project.
-- Existing tasks table and its owner-scoped RLS policies are preserved. The verified
-- table already has: id, user_id, title, description, due_date, time_period, due_hour,
-- category, priority, is_completed, google_calendar_id, google_event_id,
-- calendar_synced_at, created_at, updated_at.
-- app_data stores the legacy app's optional note without replacing description.
alter table public.tasks add column if not exists app_data jsonb not null default '{}'::jsonb;
