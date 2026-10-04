# Playable offline milestone

Implement the agreed pass-the-phone Flutter game, extending the foundation branch.

1. Test engine boundaries: 3–20 players, unique nonempty IDs/names, 1–3 imposters strictly fewer than half the players, immutable role assignment.
2. Implement configurable multiple imposters. Keep default one-imposter behavior.
3. Add and test a ballot domain: every player votes once, no self-voting, reject unknown identities. Select as many suspects as imposters; a tie across the selection boundary requires a complete revote. Citizens win only if all selected suspects are imposters.
4. Build scrollable home/setup: editable player names, add/remove players, categories and discussion duration. Bundle starter content.
5. Build privacy-aware hold-to-reveal, discussion timer, private ballots, results and rematch. Hide roles on pointer cancellation and app background. Prevent navigation back into roles.
6. Add widget tests for a full round and accessibility layout. Add CI for formatting, analysis, tests and generated web build. Platform generation remains required locally until SDK is available.
7. Review diff, commit and push to existing PR; report validation limits accurately.

Excluded: accounts, remote database, online play, monetization, persistent stats, production store signing.
