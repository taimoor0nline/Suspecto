# Offline beta completion

Deliver all feasible remaining offline work with no custom backend.

1. Fix lazy-list widget test navigation; verify in CI.
2. Add SharedPreferences-backed settings, last player setup, bounded round history and aggregated player stats. Handle unavailable/corrupt storage without blocking play. Test save/load/reset and once-only history recording.
3. Add settings and history screens. Controls: language, theme, haptics, system click sounds; reset local data with confirmation.
4. Polish cards, avatars, transitions and role/result animations; respect reduced-motion settings. Expand reviewed original content into family-safe packs.
5. Add English/Arabic interface and Arabic word translations with RTL support. Preserve English default.
6. Add vector app branding and generate platform launcher icons in CI. Generate Android/iOS/web runners; build debug APK and web bundle, unsigned iOS build if CI permits.
7. Add privacy/store listing drafts, device QA checklist, signing instructions, and clear account-dependent release blockers. Never imply these are legally finalized or store-approved.
8. Run analysis/tests/builds in CI and push verified source. Store binaries as GitHub artifacts. No store publishing, live ads, analytics or purchases without project IDs/product setup.
