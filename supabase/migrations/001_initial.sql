-- Joynt MVP schema
-- Run in Supabase SQL editor (or via CLI) after creating the project.
-- Enables: profiles, posts, follows, appreciations, saves, comments, meal photo storage.

create extension if not exists "pgcrypto";

-- Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  handle text not null unique,
  bio text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  note text check (note is null or char_length(note) <= 140),
  photo_path text not null,
  created_at timestamptz not null default now()
);

create index if not exists posts_author_created_idx on public.posts (author_id, created_at desc);
create index if not exists posts_created_idx on public.posts (created_at desc);

create table if not exists public.follows (
  follower_id uuid not null references public.profiles (id) on delete cascade,
  following_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create table if not exists public.appreciations (
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid not null references public.posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table if not exists public.saves (
  user_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid not null references public.posts (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, post_id)
);

create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts (id) on delete cascade,
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) > 0 and char_length(body) <= 240),
  created_at timestamptz not null default now()
);

create index if not exists comments_post_created_idx on public.comments (post_id, created_at);

-- Quiet public counts (no scores / ratings)
create or replace view public.post_stats as
select
  p.id as post_id,
  coalesce(a.cnt, 0) as appreciate_count,
  coalesce(s.cnt, 0) as save_count,
  coalesce(c.cnt, 0) as comment_count
from public.posts p
left join (
  select post_id, count(*)::int as cnt from public.appreciations group by post_id
) a on a.post_id = p.id
left join (
  select post_id, count(*)::int as cnt from public.saves group by post_id
) s on s.post_id = p.id
left join (
  select post_id, count(*)::int as cnt from public.comments group by post_id
) c on c.post_id = p.id;

-- Ranking helper used by the app (score never exposed in UI)
create or replace view public.for_you_candidates as
select
  p.*,
  coalesce(ps.appreciate_count, 0) as appreciate_count,
  coalesce(ps.save_count, 0) as save_count,
  coalesce(ps.comment_count, 0) as comment_count,
  (
    coalesce(ps.appreciate_count, 0) * 1.4
    + coalesce(ps.save_count, 0) * 1.8
    + coalesce(ps.comment_count, 0) * 2.2
    + case when exists (
        select 1 from public.follows f
        where f.following_id = p.author_id
      ) then 4.0 else 0.0 end
    + (6.0 / power(greatest(extract(epoch from (now() - p.created_at)) / 3600.0, 0.2), 0.55))
  ) as rank_score
from public.posts p
left join public.post_stats ps on ps.post_id = p.id;

alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.follows enable row level security;
alter table public.appreciations enable row level security;
alter table public.saves enable row level security;
alter table public.comments enable row level security;

-- Profiles
create policy "Profiles are public"
  on public.profiles for select using (true);
create policy "Users update own profile"
  on public.profiles for update using (auth.uid() = id);
create policy "Users insert own profile"
  on public.profiles for insert with check (auth.uid() = id);

-- Posts are public; authors manage their own
create policy "Posts are public"
  on public.posts for select using (true);
create policy "Authors insert posts"
  on public.posts for insert with check (auth.uid() = author_id);
create policy "Authors delete posts"
  on public.posts for delete using (auth.uid() = author_id);

-- Follows
create policy "Follows are public"
  on public.follows for select using (true);
create policy "Users manage own follows"
  on public.follows for insert with check (auth.uid() = follower_id);
create policy "Users remove own follows"
  on public.follows for delete using (auth.uid() = follower_id);

-- Appreciations / saves / comments
create policy "Appreciations public"
  on public.appreciations for select using (true);
create policy "Appreciate as self"
  on public.appreciations for insert with check (auth.uid() = user_id);
create policy "Unappreciate as self"
  on public.appreciations for delete using (auth.uid() = user_id);

create policy "Saves public"
  on public.saves for select using (true);
create policy "Save as self"
  on public.saves for insert with check (auth.uid() = user_id);
create policy "Unsave as self"
  on public.saves for delete using (auth.uid() = user_id);

create policy "Comments public"
  on public.comments for select using (true);
create policy "Comment as self"
  on public.comments for insert with check (auth.uid() = author_id);
create policy "Delete own comment"
  on public.comments for delete using (auth.uid() = author_id);

-- Storage bucket for meal photos
insert into storage.buckets (id, name, public)
values ('meal-photos', 'meal-photos', true)
on conflict (id) do nothing;

create policy "Public read meal photos"
  on storage.objects for select
  using (bucket_id = 'meal-photos');

create policy "Auth users upload meal photos"
  on storage.objects for insert
  with check (
    bucket_id = 'meal-photos'
    and auth.role() = 'authenticated'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Owners update meal photos"
  on storage.objects for update
  using (
    bucket_id = 'meal-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Owners delete meal photos"
  on storage.objects for delete
  using (
    bucket_id = 'meal-photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
declare
  base_handle text;
begin
  base_handle := coalesce(
    nullif(regexp_replace(lower(split_part(new.email, '@', 1)), '[^a-z0-9]', '', 'g'), ''),
    'eater'
  );
  insert into public.profiles (id, display_name, handle)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'full_name', 'Joynt eater'),
    base_handle || substr(replace(new.id::text, '-', ''), 1, 4)
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
