create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  last_message_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  check (user_a < user_b)
);
create unique index conversations_pair_idx on public.conversations (user_a, user_b);

create or replace function public.ensure_conversation(p_other uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare a uuid; b uuid; cid uuid;
begin
  if auth.uid() = p_other then raise exception 'self chat not allowed'; end if;
  if auth.uid() < p_other then a := auth.uid(); b := p_other;
  else a := p_other; b := auth.uid(); end if;
  insert into public.conversations (user_a, user_b) values (a, b)
    on conflict (user_a, user_b) do update set user_a = excluded.user_a
    returning id into cid;
  return cid;
end; $$;

revoke all on function public.ensure_conversation(uuid) from public;
grant execute on function public.ensure_conversation(uuid) to authenticated;

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index messages_conv_created_idx on public.messages (conversation_id, created_at desc);

create or replace function public.touch_conversation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations set last_message_at = new.created_at
  where id = new.conversation_id;
  return new;
end; $$;
create trigger messages_touch_conv
  after insert on public.messages
  for each row execute function public.touch_conversation();
