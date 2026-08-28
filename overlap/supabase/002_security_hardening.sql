-- The Overlap: least-privilege hardening for exposed public tables.
-- Run after schema.sql. Review in staging before production.

-- Supabase RLS policies are not a substitute for grants. Explicitly remove
-- broad anon/authenticated access first, then grant only what the browser needs.

revoke all on table public.profiles from anon, authenticated;
revoke all on table public.profile_versions from anon, authenticated;
revoke all on table public.topic_responses from anon, authenticated;
revoke all on table public.comparison_invites from anon, authenticated;
revoke all on table public.comparison_submissions from anon, authenticated;
revoke all on table public.comparison_responses from anon, authenticated;
revoke all on table public.comparisons from anon, authenticated;
revoke all on table public.agreements from anon, authenticated;
revoke all on table public.check_ins from anon, authenticated;
revoke all on table public.creator_methods from anon, authenticated;

-- Signed-in users only need direct browser access to their own profile-side records.
grant select, insert, update, delete on table public.profiles to authenticated;
grant select, insert, update, delete on table public.profile_versions to authenticated;
grant select, insert, update, delete on table public.topic_responses to authenticated;
grant select, insert, update, delete on table public.comparison_invites to authenticated;
grant select, insert, update, delete on table public.creator_methods to authenticated;
grant select, insert, update, delete on table public.check_ins to authenticated;

-- Comparison submissions/responses, generated comparisons, agreements and
-- referral/reward mutation should flow through narrowly scoped server functions.
-- Do not grant anon browser writes to these tables.

-- Replace broad FOR ALL policies with explicit operation policies on profiles.
drop policy if exists "profiles owner access" on public.profiles;
create policy "profiles select own" on public.profiles
  for select to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id);
create policy "profiles insert own" on public.profiles
  for insert to authenticated
  with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);
create policy "profiles update own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id)
  with check ((select auth.uid()) is not null and (select auth.uid()) = user_id);
create policy "profiles delete own" on public.profiles
  for delete to authenticated
  using ((select auth.uid()) is not null and (select auth.uid()) = user_id);

-- The existing owner-scoped policies on child tables remain the authorization
-- boundary for authenticated browser access. A later cleanup migration can split
-- every FOR ALL child policy into per-operation policies after integration tests.

-- Service credentials must never be exposed to the browser. Edge Functions use
-- a server-only secret supplied through deployment environment variables.
