create type call_inv_state as enum ('ringing','accepted','rejected','cancelled','missed','timeout','busy');

create table public.call_invitations (
  id uuid primary key default gen_random_uuid(),
  room_name text not null,
  caller_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  has_video boolean not null default true,
  state call_inv_state not null default 'ringing',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '45 seconds',
  ended_at timestamptz,
  check (caller_id <> receiver_id)
);

create index call_inv_receiver_state_idx on public.call_invitations (receiver_id, state);
create index call_inv_caller_state_idx on public.call_invitations (caller_id, state);
create unique index call_inv_one_active_per_receiver
  on public.call_invitations (receiver_id) where state = 'ringing';
