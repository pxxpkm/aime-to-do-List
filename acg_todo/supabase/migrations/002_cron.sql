-- pg_cron 排程：每天早上 09:00 執行 notify-deadline
-- 啟用 pg_cron extension（如果尚未啟用）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每日 09:00 排程
SELECT cron.schedule(
  'notify-deadline-daily',
  '0 9 * * *',
  $$
  SELECT
    net.http_post(
      url := 'https://YOUR-PROJECT.supabase.co/functions/v1/notify-deadline',
      headers := jsonb_build_object(
        'Authorization', 'Bearer YOUR-SERVICE-ROLE-KEY',
        'Content-Type', 'application/json'
      ),
      body := '{}'::jsonb
    )
  $$
);

-- 查看排程狀態：
-- SELECT * FROM cron.job;

-- 取消排程：
-- SELECT cron.unschedule('notify-deadline-daily');
