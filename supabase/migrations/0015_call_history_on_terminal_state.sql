-- Archive call_invitations to call_history when state becomes terminal
-- (rejected, cancelled, missed, timeout, busy).
-- Accepted calls still use end-call Edge Function (duration_sec + delete).

create or replace function public.archive_call_invitation_on_terminal_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.state in ('rejected', 'cancelled', 'missed', 'timeout', 'busy')
     and old.state is distinct from new.state then
    insert into public.call_history (
      room_name,
      caller_id,
      receiver_id,
      outcome,
      has_video,
      duration_sec,
      started_at,
      ended_at
    ) values (
      new.room_name,
      new.caller_id,
      new.receiver_id,
      new.state::text::call_outcome,
      new.has_video,
      0,
      new.created_at,
      coalesce(new.ended_at, now())
    );

    delete from public.call_invitations where id = new.id;
    return null;
  end if;

  return new;
end;
$$;

drop trigger if exists call_invitations_archive_terminal on public.call_invitations;

create trigger call_invitations_archive_terminal
  after update of state on public.call_invitations
  for each row
  execute function public.archive_call_invitation_on_terminal_state();
