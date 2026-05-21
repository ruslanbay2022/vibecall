create or replace function public.search_users(q text)
returns table (id uuid, username text, display_name text, avatar_url text)
language sql stable security definer set search_path = public as $$
  select id, username, display_name, avatar_url
  from public.profiles
  where (username ilike '%' || q || '%' or display_name ilike '%' || q || '%')
    and id <> auth.uid()
  order by similarity(username, q) desc nulls last
  limit 20;
$$;

revoke all on function public.search_users(text) from public;
grant execute on function public.search_users(text) to authenticated;
