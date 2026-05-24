create type call_outcome as enum ('missed','rejected','accepted','cancelled','busy','timeout');

create table public.call_history (
  id uuid primary key default gen_random_uuid(),
  room_name text not null,
  caller_id uuid not null references public.profiles(id) on delete set null,
  receiver_id uuid not null references public.profiles(id) on delete set null,
  outcome call_outcome not null,
  has_video boolean not null default true,
  duration_sec int not null default 0,
  started_at timestamptz not null default now(),
  ended_at timestamptz
);

create index call_history_caller_idx on public.call_history (caller_id, started_at desc);
create index call_history_receiver_idx on public.call_history (receiver_id, started_at desc);
