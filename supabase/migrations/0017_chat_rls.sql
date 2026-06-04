alter table public.conversations enable row level security;
create policy conv_select on public.conversations for select
  using (auth.uid() in (user_a, user_b));

alter table public.messages enable row level security;
create policy msg_select on public.messages for select using (
  exists (
    select 1 from public.conversations c
    where c.id = messages.conversation_id and auth.uid() in (c.user_a, c.user_b)
  )
);
create policy msg_insert on public.messages for insert with check (
  auth.uid() = sender_id and exists (
    select 1 from public.conversations c
    where c.id = conversation_id and auth.uid() in (c.user_a, c.user_b)
  )
);
create policy msg_update_read on public.messages for update
  using (
    exists (select 1 from public.conversations c
      where c.id = messages.conversation_id
        and auth.uid() in (c.user_a, c.user_b)
        and auth.uid() <> messages.sender_id)
  )
  with check (true);
