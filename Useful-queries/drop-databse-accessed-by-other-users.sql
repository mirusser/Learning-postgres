
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = 'target_db'
  AND pid <> pg_backend_pid();

DROP DATABASE target_db;