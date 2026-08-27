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

-- Subscription / earned-access state. Billing remains external; this table is the app-facing entitlement ledger.
create table if not exists public.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  product_tier text not null check(product_tier in ('free','plus','together')),
  source text not null check(source in ('default','paid','referral','admin','promo')),
  starts_at timestamptz not null default now(),
  ends_at timestamptz,
  external_reference text,
  created_at timestamptz not null default now()
);

-- One stable public referral/comparison identity per profile. The raw token is shown only to the owner/client;
-- only its hash is persisted. QR codes resolve through a server endpoint, never directly against this table.
create table if not exists public.referral_links (
  id uuid primary key default gen_random_uuid(),
  owner_profile_id uuid not null references public.profiles(id) on delete cascade,
  token_hash text not null unique,
  status text not null default 'active' check(status in ('active','revoked')),
  created_at timestamptz not null default now(),
  revoked_at timestamptz,
  unique(owner_profile_id)
);

-- A referral earns credit only when the referred person completes a valid comparison.
-- Do not reward raw scans, page views, duplicate users, self-referrals, or abandoned assessments.
create table if not exists public.referral_conversions (
  id uuid primary key default gen_random_uuid(),
  referral_link_id uuid not null references public.referral_links(id) on delete cascade,
  referrer_user_id uuid not null references auth.users(id) on delete cascade,
  referred_user_id uuid references auth.users(id) on delete set null,
  comparison_id uuid references public.comparisons(id) on delete set null,
  status text not null default 'pending' check(status in ('pending','qualified','rejected','rewarded')),
  rejection_reason text,
  qualified_at timestamptz,
  rewarded_at timestamptz,
  created_at timestamptz not null default now(),
  unique(referral_link_id, referred_user_id)
);

create table if not exists public.referral_rewards (
  id uuid primary key default gen_random_uuid(),
  conversion_id uuid not null unique references public.referral_conversions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reward_months integer not null default 1 check(reward_months = 1),
  reward_year integer not null,
  granted_at timestamptz not null default now()
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
alter table public.entitlements enable row level security;
alter table public.referral_links enable row level security;
alter table public.referral_conversions enable row level security;
alter table public.referral_rewards enable row level security;

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

create policy "entitlements owner read" on public.entitlements
  for select using (auth.uid() = user_id);

create policy "referral link owner read" on public.referral_links
  for select using (exists(select 1 from public.profiles p where p.id=owner_profile_id and p.user_id=auth.uid()));

create policy "referral conversion owner read" on public.referral_conversions
  for select using (auth.uid() = referrer_user_id);

create policy "referral reward owner read" on public.referral_rewards
  for select using (auth.uid() = user_id);

-- Public invite/referral submission and all reward mutation must be implemented through narrowly-scoped
-- server functions / Edge Functions, NOT broad anonymous table policies. Token hashes must never be exposed.
-- Reward policy: 1 qualified completed comparison = 1 month of Plus, maximum 6 referral months in a rolling
-- 12-month period per user. Enforce that limit transactionally server-side before granting entitlement time.
-- Add abuse checks for self-referrals, duplicate identities, repeated device/payment signals where lawful,
-- impossible-speed completions, and revoked links. Do not collect invasive fingerprinting just to police rewards.
-- Add server-side RPCs for invite lookup, guest submission, comparison reveal, referral qualification,
-- reward grant, revocation, export, and deletion.