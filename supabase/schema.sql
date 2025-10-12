-- Enable extensions
create extension if not exists "pgcrypto";
create extension if not exists "uuid-ossp";

-- USERS
create table if not exists public.users (
  id uuid primary key default gen_random_uuid(),
  alias text not null check (char_length(alias) between 3 and 24),
  created_at timestamptz not null default now()
);

-- LEADERBOARD (weekly)
create table if not exists public.leaderboard (
  id bigserial primary key,
  user_id uuid not null references public.users(id) on delete cascade,
  week_start date not null,
  score int not null default 0,
  updated_at timestamptz not null default now(),
  unique (user_id, week_start)
);

alter table public.users enable row level security;
alter table public.leaderboard enable row level security;

create policy if not exists "select_own_user"
  on public.users for select
  using (id = auth.uid());

create policy if not exists "insert_user_self"
  on public.users for insert
  with check (id = auth.uid());

create policy if not exists "update_user_self"
  on public.users for update
  using (id = auth.uid());

create policy if not exists "select_scores"
  on public.leaderboard for select
  using (true);

create policy if not exists "upsert_own_score"
  on public.leaderboard for insert
  with check (user_id = auth.uid());

create policy if not exists "update_own_score"
  on public.leaderboard for update
  using (user_id = auth.uid());

create or replace function public.leaderboard_upsert_sum()
returns trigger language plpgsql as $$
begin
  if (tg_op = 'UPDATE') then
    new.score := coalesce(old.score, 0) + coalesce(new.score, 0);
    new.updated_at := now();
    return new;
  end if;
  return new;
end;
$$;

drop trigger if exists tg_leaderboard_upsert_sum on public.leaderboard;

create trigger tg_leaderboard_upsert_sum
before update on public.leaderboard
for each row execute function public.leaderboard_upsert_sum();

-- Example upsert
-- insert into public.leaderboard (user_id, week_start, score)
-- values (auth.uid(), date_trunc('week', now())::date, 10)
-- on conflict (user_id, week_start)
-- do update set score = public.leaderboard.score + excluded.score,
--               updated_at = now();
