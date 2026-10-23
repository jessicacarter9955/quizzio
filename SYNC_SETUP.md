# Quiz Lab — permanent links and Supabase synchronization

Branch: `quiz-lab-apk-builder` of `jessicacarter9955/quizzio`.

## Permanent download URLs

- Latest ARM64 preview: https://github.com/jessicacarter9955/quizzio/releases/download/latest-preview/Quiz-Lab-Yellow-ARM64-Latest.apk
- Stable release page: https://github.com/jessicacarter9955/quizzio/releases/tag/latest-preview
- Previous v19 preview (archived): https://github.com/jessicacarter9955/quizzio/releases/tag/v19-preview

A GitHub Release asset persists until a maintainer deliberately deletes the asset/release/repository; Actions artifacts expire. The repository is private, so GitHub authentication is required to download it.

## Web links and hosting

- Current deployed web: https://quizlab-language-sync.humbleroot256.chatgpt.site (version 1 deployed 23 Oct 2026, owner-only access; do not use an ephemeral preview URL)
- Old Render mobile: https://quizlab-mobile-games.onrender.com (currently suspended)
- Old Render responsive: https://quizlab-responsive-web.onrender.com (currently suspended)

Render's authenticated service metadata confirms `suspenders: ["billing"]` for both services. Restoring those same old URLs requires resolving billing on that Render workspace. A redeploy alone cannot remove this account-level suspension. The new independent Quiz Lab Site has a durable URL while the owner retains the Site and hosting remains active, but owner-only access may require signing in. Its quiz/play/patterns/stats UI was checked in a live local browser preview before publishing. The initial production deployment succeeded; cross-device Supabase login remains untested until project provisioning.

## Supabase requirements

A dedicated Supabase project is required; do not use a service-role key in client apps.

1. In Supabase SQL Editor, execute [supabase/schema.sql](supabase/schema.sql) once; it is idempotent and enables strict user-scoped Row Level Security (RLS).
2. Enable email/password sign-in under Supabase Auth; verify the project and email confirmation setting.
3. Configure **GitHub Actions repository secrets** `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` for the Android release workflow. Both are supplied to Flutter as `--dart-define` values. The publishable key is public; never use `service_role`.
4. For the web source, define before `app.js`:

   ```html
   <script>
   window.QUIZLAB_SUPABASE_CONFIG = {
     url: 'https://YOUR-PROJECT.supabase.co',
     publishableKey: 'sb_publishable_...'
   };
   </script>
   ```

   The web build must load `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2` before `app.js`, as configured in `web-v2-index.html` / `web-responsive-index.html`.
5. Use the *same* Supabase Auth account on mobile and web; log into **Cloud progress** on web and **Supabase Cloud** on mobile. The first login imports historical local attempts instead of discarding them.

## Implementation & limitations

- Web quiz answers, writing attempts and pattern attempts are uploaded with persistent event IDs.
- Mobile quiz answers are stored with persistent event IDs in SQLite and uploaded on sign-in, manual sync, and after answering. Existing SQLite answers are given IDs during the first sync. Remote answers merge by ID; 3·2·1 progress is replayed on the union and statistics derive from the merged attempts.
- Sync is offline-first and idempotent; it never bulk-overwrites counters or deletes local study history.
- Mobile writing and similarity preferences, and cross-platform manual topic-selection preferences, are **not yet fully bidirectional**.
- Different vocabulary pack IDs or mismatched source datasets cannot be safely merged until verified. Data identity must be checked with production content.
- Concurrent multi-device events are ordered by timestamp + event ID. Users should keep device clocks reasonably accurate.
- No live Supabase project has been provisioned or connected yet. Client binaries built without the two GitHub secrets remain offline-only. The static web needs its public config as above.
- Signing is still an Android preview signing configuration. A GitHub Releases URL is permanent, but installing over a previous preview with a different signing certificate may require uninstalling the old preview, which could erase local-only data. Back up progress before doing so.

## Verification checklist

- [ ] Supabase project created and schema applied
- [ ] GitHub Actions Supabase secrets configured
- [ ] Web public runtime config present in deployment
- [x] Alternative owner-only Site deployed successfully and local browser quiz answered
- [ ] Render billing resolved and both legacy services return HTTP 200 (only if legacy URLs are still wanted)
- [ ] One account used on both clients
- [ ] Offline mobile quiz attempts become visible on web
- [ ] Offline web attempts become visible on mobile after reopening/syncing
- [ ] Same event retried 3 times is counted once
- [ ] 3·2·1 milestone parity manually verified for the same vocabulary ID
- [ ] Future releases use a stable signing certificate
