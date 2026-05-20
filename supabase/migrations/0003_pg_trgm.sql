create extension if not exists pg_trgm;

create index profiles_username_trgm_idx on public.profiles
  using gin (username gin_trgm_ops);

create index profiles_display_name_trgm_idx on public.profiles
  using gin (display_name gin_trgm_ops);
