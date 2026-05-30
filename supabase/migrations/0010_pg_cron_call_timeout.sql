create extension if not exists pg_cron;

create or replace function public.expire_old_call_invitations()
returns void language sql security definer set search_path = public as $$
  update public.call_invitations
  set state = 'missed', ended_at = now()
  where state = 'ringing' and expires_at < now();
$$;

select cron.schedule(
  'expire-call-invitations',
  '*/1 * * * *',
  $$ select public.expire_old_call_invitations(); $$
);
