-- Step 3.7: incoming call listener needs Realtime INSERT on call_invitations.
-- Without this, receiver clients never get notifyIncoming().

alter table public.call_invitations replica identity full;

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'call_invitations'
  ) then
    alter publication supabase_realtime add table public.call_invitations;
  end if;
end $$;
