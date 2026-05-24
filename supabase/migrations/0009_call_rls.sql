alter table public.call_invitations enable row level security;
create policy ci_select on public.call_invitations for select
  using (auth.uid() in (caller_id, receiver_id));
create policy ci_insert on public.call_invitations for insert
  with check (auth.uid() = caller_id);
create policy ci_update_receiver on public.call_invitations for update
  using (auth.uid() = receiver_id) with check (auth.uid() = receiver_id);
create policy ci_update_caller_cancel on public.call_invitations for update
  using (auth.uid() = caller_id and state = 'ringing')
  with check (auth.uid() = caller_id and state in ('cancelled','ringing'));

alter table public.call_history enable row level security;
create policy ch_select on public.call_history for select
  using (auth.uid() in (caller_id, receiver_id));
