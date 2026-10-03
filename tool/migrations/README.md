# Roster migration runbook

This is an operator-run migration, not app startup code. Always specify the verified project ID explicitly; never infer that data is disposable from a project name. All private
exports, conflict reports and verification reports belong in `.release-private/`
outside Git. Never paste exported student information into a PR or build log.

1. Sign in with an existing project administrator and use authorized Application
   Default Credentials. Inventory **all** Firestore collections/subcollections,
   deployed rules, indexes, functions and trusted staff identities. Save the
   currently deployed rules and release identifiers privately for rollback.
   `roster.rules` is a candidate until this inventory is reconciled; do not deploy
   it over unrelated production namespaces. Do not copy self-editable `users.role`
   into trusted `staff_access`. Confirm each role and authorized location IDs.
2. Run `node tool/migrations/roster-admin.cjs export PROJECT
   .release-private/backup-before.json`. This includes nested collections and
   typed timestamps, document references and bytes. Run `roster-plan.cjs BACKUP
   YYYY-MM-DD .release-private/plan.json` for a deterministic dry-run. The date is
   a migration baseline for **unknown** enrollment starts, never proof of actual
   entry. Investigate every conflict; do not hand-edit the generated plan.
3. Prepare the required Firestore Rules and indexes using
   `firebase/roster.deploy.json`; retain unrelated existing namespaces and indexes.
   This configuration has no Functions deployment. Do not recreate the retired
   callable or scheduler. For the current direct-client cutover, follow
   [the client cutover runbook](../../docs/testing/2026-10-03-roster-client-cutover.md),
   including its write barriers and independent confirmation of Function removal.
   Build/test the iOS release before the short production cutover. Existing build
   9 does not honor app_config maintenance, so that flag alone is **not** a barrier.
4. Establish a short cutover window. Deploy and verify rules that prevent old
   clients writing legacy daily records, student membership or reward counts.
   Keep unrelated required reads/operations intact. Only after verifying the
   server barrier set app_config/roster to `{status: maintenance,
   legacyWritesBlocked: true}`. Export again and regenerate the final plan from
   this frozen source. Reconcile the difference from the initial dry-run.
5. Run `roster-admin.cjs apply PROJECT BACKUP PLAN .release-private/apply.json`,
   then `roster-admin.cjs verify PROJECT BACKUP PLAN .release-private/verify.json`.
   Apply refuses changed sources, unknown existing destination data, edited plans,
   and a removed maintenance barrier. It only merges membership metadata into
   profiles; new records are created with a migration fingerprint. Interrupted
   apply can resume with the **same** backup/plan. Verify checks record contents,
   counts, unchanged legacy sources and rewards. Never use a broad delete/restore
   as an automatic rollback. A failure leaves maintenance active for reconciliation.
6. Compare per-site current rosters, the previously missing 13 IDs, orphan histories,
   date-format collisions, archive/transfer boundaries and staff access. Verify real
   bounded queries against deployed indexes; Emulator cannot prove index readiness.
   Enable the new app only after this check and Apple processing. Confirm the build
   is available in the existing TestFlight group; uploading an IPA is insufficient.

Legacy defaults remain `legacyUnverified`. Confirming a remark cannot validate old
scores. No migration creates attendance for a missing row or replays legacy awards.
Rollback after new writes requires a forward repair or a separately reviewed merge;
simply reenabling old clients would reintroduce lost updates and stale daily arrays.

Install the pinned Admin SDK with `npm ci --ignore-scripts --prefix tool/migrations`.
The SDK belongs to these operator tools; it does not create a Cloud Function.
Run the pure planner and retirement checks with `npm --prefix tool/migrations test`.
The steps above describe the legacy-array import; the client cutover runbook
covers the subsequent metadata migration. Do not apply an old import plan to an
already migrated database.

Local verification uses only `demo-yellow-ribbon-roster` on 127.0.0.1:8190:

```
firebase emulators:exec --only firestore --project demo-yellow-ribbon-roster --config firebase/roster-emulator.json "npm --prefix tool/migrations run test:migration"
```
