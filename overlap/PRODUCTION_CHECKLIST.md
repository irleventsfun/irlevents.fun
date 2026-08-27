# The Overlap — Path to 100%

Tagline: **This is not a dating app.**

## Already working
- Standalone visual identity and product positioning
- Mobile-first browser interface
- Couple and single/comparison entry paths
- 12-topic values/threshold assessment
- Private local autosave and answer review
- Reusable partner-comparison prototype flow
- Comparison results and overlap bands
- 14-day agreement builder
- DEAR MAN preparation
- Conversation chess timer
- Creator-method notes and resource shelf
- Demo data
- GitHub Pages deployment workflow

## Required for a real private beta
1. Create a dedicated Supabase project for The Overlap.
2. Run `supabase/schema.sql` after review.
3. Add passwordless Auth (magic link and/or email OTP).
4. Replace localStorage profile persistence with authenticated cloud persistence.
5. Implement invite creation using random opaque tokens; store only token hashes.
6. Implement invite lookup and guest submission through server-side RPC/Edge Functions.
7. Reveal comparison results only after the submission rules are satisfied.
8. Add revoke, expire, regenerate, and rate-limit controls for invite links.
9. Add transactional email for sign-in, invite, invite-completed, and plan-review messages.
10. Add account export, comparison deletion, invite deletion, and account deletion.
11. Add privacy policy, terms, retention policy, breach-response contact, and support contact.
12. Add safe handling for sexual-intimacy questions: optional, skippable, no implied obligation.
13. Never send intimate free-text answers or exact slider values to analytics providers.
14. Add a visible help/safety route when a user reports coercion, fear, or unsafe conflict.
15. Test with real couples across device types before calling any scoring language final.

## Recommended architecture
- Frontend: keep the current lightweight app for beta or migrate to Next.js when account routing becomes complex.
- Auth/database: Supabase Auth + Postgres.
- Authorization: Postgres Row Level Security plus server-side functions for anonymous invite flows.
- Email: Resend or Supabase-compatible SMTP.
- Hosting: standalone domain on Cloudflare/Vercel/Pages; do not present it as an IRL Events product.
- Analytics: aggregate page/event analytics only. Do not capture intimate response payloads.

## Product rules that should remain non-negotiable
- No compatibility verdict or “you should break up” output.
- No public dating profiles, discovery feed, swiping, or partner leaderboard.
- Private notes stay private unless the author explicitly shares them.
- Sensitive questions are always optional.
- Comparison invitations never expose the owner dashboard.
- The app is educational/reflection software, not therapy, diagnosis, abuse assessment, or emergency support.

## Definition of 100%
For this project, “100%” should mean **production-ready private beta**, not “all future features finished.” It is 100% when two people can independently create/access accounts, securely complete assessments on separate devices, receive/revoke invitations, see the intended comparison only after submission, run a 14-day plan, receive the planned emails/reminders, export/delete their data, and understand the privacy/safety boundaries without any manual developer intervention.

## External configuration still required
These cannot be safely invented or committed to GitHub:
- Supabase project URL and anon/publishable key
- Supabase service credentials (server only)
- Email provider API key/domain verification
- Final standalone domain and DNS records
- Legal/support contact information

Keep secrets in deployment environment variables, never source control.
