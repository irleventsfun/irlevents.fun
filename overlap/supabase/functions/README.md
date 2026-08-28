# The Overlap — server function contracts

These endpoints are the server-side trust boundary for invitation, comparison, referral, reward, export, and deletion flows. They should be implemented as Supabase Edge Functions (or equivalent server routes) once Cameron supplies the project/environment configuration.

## Public / invite-safe functions

### `resolve-invite`
Input: opaque invite/referral token.
Returns only the minimum public invitation metadata needed to start a comparison (owner display name, invitation type, expiration status). Never returns owner answers, email, dashboard data, or token hashes.

### `submit-comparison`
Input: opaque invite token + guest profile/assessment payload.
Validates token, status, expiration and request shape; creates the guest submission and responses transactionally; marks the invitation completed; creates the comparison; records referral conversion when applicable. Never grants the guest unrestricted table access.

## Authenticated functions

### `create-comparison-link`
Creates or rotates the signed-in user's stable public comparison/referral link. Generate a cryptographically random token, persist only a hash, and return the raw token once to the client for URL/QR construction.

### `revoke-comparison-link`
Revokes the current public link immediately.

### `qualify-referral-reward`
Server-only/internal. Runs after a valid comparison is completed. Enforces:
- no reward for a scan/open alone;
- no self-referral;
- no replay/duplicate conversion;
- one reward per qualified completed comparison;
- maximum six referral-earned Overlap+ months in any rolling 12-month period;
- rewards have no cash value and apply only to Overlap+.

### `export-account`
Produces a user-controlled export containing the signed-in user's profile, versions, responses, comparison metadata they are entitled to see, plans, notes/methods, preferences, and entitlement history. Do not include another person's private notes or unshared raw answers.

### `delete-account`
Deletes or anonymizes all records according to the published retention policy and logs only the minimum audit fact needed to demonstrate the request was completed.

## Security rules
- Validate JWTs for authenticated functions.
- Use service-role credentials only inside server runtime secrets.
- Do not log assessment text, private notes, exact slider values, sexual-intimacy responses, access tokens, magic links, or raw invite/referral tokens.
- Rate-limit public invite resolution and submission.
- Use structured validation with strict maximum field lengths.
- Return generic errors that do not reveal whether another user's private record exists.
- Keep CORS allow-lists explicit in production.
