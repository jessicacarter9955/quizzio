-- Run in the Supabase SQL Editor before using Quiz Lab cloud uploads.
-- Each user owns and may modify only their own JSON quiz packs.
create table if not exists public.quiz_packs (
  owner_id uuid not null references auth.users(id) on delete cascade,
  pack_id text not null check (length(pack_id) between 1 and 200),
  pack_type text not null check (pack_type in ('quiz', 'language')),
  title text not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (owner_id, pack_id)
);

alter table public.quiz_packs enable row level security;

-- Explicit privileges: never let unauthenticated clients access packs.
revoke all on table public.quiz_packs from anon;
grant select, insert, update, delete on table public.quiz_packs to authenticated;

-- Idempotent migration: remove old policies with the same names before recreating.
drop policy if exists "quiz_packs_read_own" on public.quiz_packs;
drop policy if exists "quiz_packs_insert_own" on public.quiz_packs;
drop policy if exists "quiz_packs_update_own" on public.quiz_packs;
drop policy if exists "quiz_packs_delete_own" on public.quiz_packs;

create policy "quiz_packs_read_own" on public.quiz_packs
  for select to authenticated using (owner_id = (select auth.uid()));
create policy "quiz_packs_insert_own" on public.quiz_packs
  for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "quiz_packs_update_own" on public.quiz_packs
  for update to authenticated using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));
create policy "quiz_packs_delete_own" on public.quiz_packs
  for delete to authenticated using (owner_id = (select auth.uid()));

-- Cross-device language-quiz answer log. Every answer is an immutable event;
-- on reconnection clients union events by ID then replay their 3-2-1 state.
-- This avoids the lost-update problem of syncing aggregate counters.
create table if not exists public.quiz_sync_events (
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id text not null check (length(event_id) between 8 and 160),
  event_type text not null check (event_type in ('quiz_answer', 'writing_attempt',
      'pattern_attempt', 'similarity_rating', 'selection_change')),
  occurred_at timestamptz not null,
  payload jsonb not null check (jsonb_typeof(payload) = 'object'),
  received_at timestamptz not null default now(),
  primary key (user_id, event_id)
);
create index if not exists quiz_sync_events_by_user_time
  on public.quiz_sync_events (user_id, occurred_at, event_id);
alter table public.quiz_sync_events enable row level security;
revoke all on public.quiz_sync_events from anon;
grant select, insert on public.quiz_sync_events to authenticated;
drop policy if exists "quiz_sync_read_own" on public.quiz_sync_events;
drop policy if exists "quiz_sync_insert_own" on public.quiz_sync_events;
create policy "quiz_sync_read_own" on public.quiz_sync_events
  for select to authenticated using (user_id = (select auth.uid()));
create policy "quiz_sync_insert_own" on public.quiz_sync_events
  for insert to authenticated with check (user_id = (select auth.uid()));
