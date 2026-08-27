-- The Overlap production schema (baseline)
-- Run in a dedicated Supabase project. Review before production use.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  mode text not null check (mode in ('couple','single')),
  attachment_pattern text,
  active_version_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
);

create table if not exists public.profile_versions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  version_number integer not null,
  published_at timestamptz not null default now(),
  unique(profile_id, version_number)
);

alter table public.profiles
  add constraint profiles_active_version_fk
  foreign key (active_version_id) references public.profile_versions(id) on delete set null;

create table if not exists public.topic_responses (
  id uuid primary key default gen_random_uuid(),
  profile_version_id uuid not null references public.profile_versions(id) on delete cascade,
  topic_id text not null,
  ideal numeric,
  flex_range numeric,
  flex_ease numeric,
  contribution numeric,
  note text,
  skipped boolean not null default false,
  unique(profile_version_id, topic_id)
);

create table if not exists public.comparison_invites (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  token_hash text not null unique,
  status text not null default 'open' check(status in ('open','completed','revoked','expired')),
  expires_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.comparison_submissions (
  id uuid primary key default gen_random_uuid(),
  invite_id uuid not null references public.comparison_invites(id) on delete cascade,
  guest_user_id uuid references auth.users(id) on delete set null,
  display_name text not null,
  email text,
  attachment_pattern text,
  submitted_at timestamptz not null default now(),
  unique(invite_id)
);

create table if not exists public.comparison_responses (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null references public.comparison_submissions(id) on delete cascade,
  topic_id text not null,
  ideal numeric,
  flex_range numeric,
  flex_ease numeric,
  contribution numeric,
  note text,
  skipped boolean not null default false,
  unique(submission_id, topic_id)
);

create table if not exists public.comparisons (
  id uuid primary key default gen_random_uuid(),
  owner_profile_version_id uuid not null references public.profile_versions(id) on delete cascade,
  submission_id uuid not null references public.comparison_submissions(id) on delete cascade,
  generated_at timestamptz not null default now(),
  unique(owner_profile_version_id, submission_id)
);

create table if not exists public.agreements (
  id uuid primary key default gen_random_uuid(),
  comparison_id uuid not null references public.comparisons(id) on delete cascade,
  topic_id text not null,
  baseline text,
  ownership_json jsonb not null default '{}'::jsonb,
  dear_man_json jsonb not null default '{}'::jsonb,
  timer_minutes integer,
  review_date date,
  status text not null default 'active' check(status in ('active','completed','abandoned')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.check_ins (
  id uuid primary key default gen_random_uuid(),
  agreement_id uuid not null references public.agreements(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  battery integer check(battery between 0 and 100),
  battery_reason text,
  can_give text,
  needs_protected text,
  adjustment text,
  created_at timestamptz not null default now()
);

create table if not exists public.creator_methods (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  creator_name text not null,
  method_name text not null,
  source_url text,
  summary text,
  steps text,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.profile_versions enable row level security;
alter table public.topic_responses enable row level security;
alter table public.comparison_invites enable row level security;
alter table public.comparison_submissions enable row level security;
alter table public.comparison_responses enable row level security;
alter table public.comparisons enable row level security;
alter table public.agreements enable row level security;
alter table public.check_ins enable row level security;
alter table public.creator_methods enable row level security;

create policy "profiles owner access" on public.profiles
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "profile versions owner access" on public.profile_versions
  for all using (exists(select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid()))
  with check (exists(select 1 from public.profiles p where p.id = profile_id and p.user_id = auth.uid()));

create policy "topic responses owner access" on public.topic_responses
  for all using (exists(select 1 from public.profile_versions v join public.profiles p on p.id=v.profile_id where v.id=profile_version_id and p.user_id=auth.uid()))
  with check (exists(select 1 from public.profile_versions v join public.profiles p on p.id=v.profile_id where v.id=profile_version_id and p.user_id=auth.uid()));

create policy "invites owner access" on public.comparison_invites
  for all using (exists(select 1 from public.profiles p where p.id=owner_profile_id and p.user_id=auth.uid()))
  with check (exists(select 1 from public.profiles p where p.id=owner_profile_id and p.user_id=auth.uid()));

create policy "creator methods owner access" on public.creator_methods
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "checkins owner access" on public.check_ins
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Public invite submission should be implemented through narrowly-scoped server functions / Edge Functions,
-- NOT broad anonymous table policies. Token hashes should never be exposed to the browser.
-- Add server-side RPCs for invite lookup, guest submission, comparison reveal, revocation, export, and deletion.
