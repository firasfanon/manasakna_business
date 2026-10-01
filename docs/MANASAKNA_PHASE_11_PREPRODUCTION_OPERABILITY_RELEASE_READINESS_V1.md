# Manasakna Business Phase 11 — Preproduction Operability & Release Readiness

Status: ENGINEERING_EVIDENCE_COMPLETE_PENDING_SEPARATE_INTEGRATION_AND_BASELINE_DECISION

## Authorized exact base

- Business head: `e32c3a3b6cc5d8f8878bdb006cce2f7ba44a637d`
- Business tree: `493ea2f4ba39c0df767b465b844b0f7c6c3b64e4`
- Branch: `task/MANASAKNA-BUSINESS-PHASE11-PREPROD-OPERABILITY-RELEASE-READINESS-V1`
- Execution device: `Futuer-IT`

## Governing boundaries

```text
HAJJ_SOVEREIGN_AUTHORITY=PROHIBITED
DB_MUTATION=NO
REAL_PROVIDER=NO
REAL_DATA=NO
PRODUCTION=NO
STORE_RELEASE=NO
MAIN_MERGE_AUTHORITY=NO
BASELINE_PROMOTION_AUTHORITY=NO
```
## Phase 11 changes

- Stale user-visible `Phase 7 Preview` label replaced by truthful preproduction wording.
- Web identity/manifest now uses Arabic product identity and RTL metadata.
- Accessible bootstrap loading state is removed on first Flutter frame.
- Privacy-safe bounded memory-only diagnostics added for Flutter framework, platform-dispatcher and guarded-zone failures.
- Diagnostics retain no exception message, stack trace, tenant payload, payment/traveler data or external telemetry.
- Noto Sans Arabic is bundled locally under OFL.
- Flutter fallback fonts are redirected to same-origin `fallback_fonts/`.
- The exact Roboto fallback requested by Flutter is bundled locally under OFL.
- Phase 10 synthetic-provider and tenant-authority gates remain unchanged.

## Verification

- Phase 11 targeted tests: PASS (6)
- Full Flutter suite: PASS (40)
- Analyzer: PASS / no issues
- Release Web build: PASS
- External font/CDN requests during blocked-DNS UAT:
  - `fonts.gstatic.com=0`
  - `www.gstatic.com=0`
  - `fonts.googleapis.com=0`
- Local fallback font request observed: YES
- Desktop visual UAT: PASS
- 390px visual UAT: PASS
- Restart/recovery HTTP readback: PASS / 200
## Release artifact

Business remains a Web console in this repository.

- Web `main.dart.js`
  - bytes: 2,187,400
  - SHA-256: `e1d48d786e7df123bb1495833f54893e62c68500826a15527ea81e8cc4a863c1`

No production deployment, provider activation, real credentials, Store release, shared DB mutation or sovereign Hajj authority was introduced.

## Authority regression evidence

Full-suite tests continue to prove:
- tenant membership cannot fall through to another tenant;
- role scopes remain tenant-local;
- Hajj sovereign scopes are prohibited for every commercial role;
- unconfigured console fails closed;
- real/unmarked provider data is rejected;
- payment remains preview-only;
- messaging never claims delivery;
- travel never calls live inventory;
- provider failure becomes explicit unavailable state.

## Gate result

```text
G11-0=PASS
G11-1=PASS
G11-2=PASS
G11-3=PASS
G11-4=PASS
G11-5=PASS
G11-6=PASS
G11-FINAL=ENGINEERING_EVIDENCE_COMPLETE
```

Next authority gate: separate integration and sovereign baseline decision.
