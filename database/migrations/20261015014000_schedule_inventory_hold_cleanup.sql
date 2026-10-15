-- Return abandoned walk-in cart stock shortly after its 15-minute hold expires.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cron.job WHERE jobname = 'inventory-hold-cleanup'
  ) THEN
    PERFORM cron.schedule(
      'inventory-hold-cleanup',
      '* * * * *',
      'select public.release_expired_inventory_holds();'
    );
  END IF;
END;
$$;
