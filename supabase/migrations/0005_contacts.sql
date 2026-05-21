create type contact_status as enum ('pending', 'accepted', 'blocked');

create table public.contacts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  contact_id uuid not null references public.profiles(id) on delete cascade,
  status contact_status not null default 'pending',
  created_at timestamptz not null default now(),
  unique (user_id, contact_id),
  check (user_id <> contact_id)
);

create index contacts_user_idx on public.contacts (user_id, status);
create index contacts_contact_idx on public.contacts (contact_id, status);

alter table public.contacts enable row level security;

create policy contacts_select_own on public.contacts for select
  using (auth.uid() = user_id or auth.uid() = contact_id);

create policy contacts_insert_own on public.contacts for insert
  with check (auth.uid() = user_id);

create policy contacts_update_involved on public.contacts for update
  using (auth.uid() = user_id or auth.uid() = contact_id);

create policy contacts_delete_involved on public.contacts for delete
  using (auth.uid() = user_id or auth.uid() = contact_id);
