# Personal Unsigned IPA Workflow Implementation Plan

> **For agentic workers:** execute this plan task-by-task using the native in-session workflow. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a downloadable, unsigned iOS IPA for the personal Feather-based app through GitHub Actions, then let iLoader sign and install it from Windows.

**Architecture:** Keep Feather's Xcode project and existing build as the base. Remove the shared `backloop.dev` private TLS key download/embed path from all Makefile targets, build an unsigned IPA to an explicit Xcode products directory, and add a manual GitHub Actions workflow that uploads the IPA as an artifact. The IPA contains no Apple Developer identity or provisioning profile; iLoader performs the first-install signing.

**Tech Stack:** Swift, Xcode 27, Makefile, GitHub Actions, iLoader on Windows.

**Spec:** `C:\Users\ren11\Documents\Codex\2026-11-02\referenced-chatgpt-conversation-this-is-an\outputs\ios27-sideload-architecture-ja.md`

## Global Constraints

- Target is one personal iPhone 16e running iOS 27.0.1.
- GitHub Actions must not receive an Apple Account password, 2FA code, `.p12`, API key, or private TLS key.
- The Actions artifact is an unsigned IPA with no `embedded.mobileprovision`; iLoader signs it at installation time.
- The host bundle ID must be a stable user-supplied workflow input so later updates replace the same app and retain the reserved host slot.
- Use the `xcode-27` GitHub-hosted runner and keep iOS build output separate from the existing Catalyst release artifact.
- Do not add or run tests; use the requested GitHub Actions build and artifact output as the packaging check.

## Review Focus

- Bundle ID input validation rejects malformed values and is consistently passed to Xcode and IPA metadata.
- The artifact contains no Apple signing identity, provisioning profile, or shared TLS private key.
- The archive layout is exactly `Payload/<app>.app` at the IPA root and can be imported by iLoader.
- The workflow is least-privilege, manually triggered, and retains a clearly named artifact for download.
- Existing LocalDevVPN/Pairing installation remains the intended iPhone-only path after bootstrap; the server certificate installer is not silently presented as available without a user-owned TLS identity.

---

### Task 1: Separate unsigned iOS packaging from TLS certificate setup

**Files:**
- Modify: `Makefile`
- Modify: `Feather/Views/Settings/Installation/Server & SSL/ServerView.swift`
- Modify: `Feather/Views/Library/Install/InstallPreviewView.swift`
- Modify: `Feather/Backend/Server/ServerInstaller.swift`
- Modify: `Feather/Utilities/FR.swift`

**Interfaces:**
- `make ipa-unsigned BUNDLE_ID=<stable.bundle.id>` builds only the iOS target and writes `packages/Feather-unsigned.ipa`.
- The target invokes `xcodebuild` with `CODE_SIGNING_ALLOWED=NO`, passes `BUNDLE_ID` as the product bundle ID, packages `Payload/Feather.app`, and does not call a remote TLS-key endpoint.
- No Makefile target downloads or embeds the shared `backloop.dev` TLS private key. LocalDevVPN/Pairing and the HTTP Semi Local install path remain available.

- [x] **Step 1: Define the unsigned IPA target** in `Makefile` with an explicit products directory and stable Bundle ID input.
- [x] **Step 2: Remove shared-key retrieval** from all Makefile targets and from runtime server settings; retain LocalDevVPN/Pairing and force the server installer and UI to HTTP Semi Local, including after upgrades with stale settings.
- [x] **Step 3: Package the unprovisioned app** as `Payload/Feather.app` without invoking code signing or embedding a provisioning profile in the unsigned target.
- [x] **Step 4: Review** the Makefile and Swift call sites; no shared private-key endpoint remains.

### Task 2: Add a GitHub Actions unsigned-IPA artifact workflow

**Files:**
- Create: `.github/workflows/unsigned-ipa.yml`
- Modify: `Makefile` only if Task 1 exposes an input propagation gap

**Interfaces:**
- Trigger: `workflow_dispatch` with required `bundle_id` input.
- Runner: `xcode-27`.
- Output: artifact named `feather-unsigned-ipa-<run-number>` containing the IPA and a build-info text file with commit, bundle ID, and Xcode version.

- [x] **Step 1: Define the manual workflow** with `contents: read`, pinned checkout/artifact actions, a bounded concurrency group, and input validation for the bundle identifier.
- [x] **Step 2: Build** by checking out submodules, reporting the selected Xcode version, and running `make ipa-unsigned BUNDLE_ID=...`.
- [x] **Step 3: Upload** only the unsigned IPA and build metadata; no secrets, certificates, or intermediate key files are uploaded.
- [x] **Step 4: Keep release tags separate**; the workflow produces a personal-use artifact and no GitHub Release.

### Task 3: Document the Windows iLoader bootstrap

**Files:**
- Create: `docs/BUILDING_AND_INSTALLING.md`

**Interfaces:**
- Explain how to dispatch the workflow, download the artifact, install iTunes drivers/iLoader, connect and trust the iPhone, sign/install the IPA through iLoader, and retain the same bundle ID for updates.
- State that Apple Account credentials are entered into iLoader on the user's PC, never in GitHub Actions.

- [x] **Step 1: Write the workflow and download steps** using the repository's artifact name and required input; note that workflow_dispatch needs the workflow on the fork's default branch.
- [x] **Step 2: Document first-install requirements and recovery**: Developer Mode when requested, trust/pairing, retain the IPA, and use the same bundle ID for reinstall/update.
- [x] **Step 3: Record the source/license notice** for the Feather GPL-3.0 fork and clarify that the artifact is a personal build, not an upstream Feather release.

### Task 4: Review the local changes and prepare the Actions run

**Files:**
- Review: all files above

- [x] **Step 1: Inspect the diff** for unrelated changes, signing credentials, shared-key references, and workflow permission excess.
- [x] **Step 2: Confirm** no user-owned GitHub remote is configured; do not push to the upstream Feather repository.
- [x] **Step 3: Stop for user review** before pushing to a personal fork; the user must provide/authorize the target repository before an Actions run can occur.

## Out of Scope for This First IPA Milestone

- LiveContainer Guest Runtime integration, certificate-pool GUI, Personal Team on-device signing, Shortcuts refresh, tweak work, and the full hybrid mode router remain subsequent implementation milestones.
- No Apple Account, signing certificate, or TLS private key is added to GitHub Secrets or the workflow.

## Sources Checked

- Apple Xcode system requirements: <https://developer.apple.com/xcode/system-requirements>
- GitHub Xcode 27 runner availability: <https://github.blog/changelog/2026-10-15-xcode-27-runner-image-generally-available/>
- iLoader official repository: <https://github.com/nab138/iloader>
- Feather existing build: `Makefile`, `.github/workflows/release.yml`, `.github/HOW_IT_WORKS.md`

## Execution Notes

- User approved implementation on 2026-11-02.
- No local Xcode build or tests were run in this Windows environment. The requested GitHub Actions build remains pending because this checkout only has the upstream `claration/Feather` remote; the workflow must be merged to a user-owned fork's default branch before `workflow_dispatch` is available.
- Reviewer caught the implicit `_build/Applications` assumption; the unsigned target now sets `CONFIGURATION_BUILD_DIR` explicitly. The legacy shared TLS key fetch/embed path was removed from all Makefile targets to satisfy the no-private-key requirement consistently.
- Reviewer caught that old `serverMethod=0` preferences could still select HTTPS without a certificate; the installer now forces the HTTP Semi Local path even when the settings screen has not been opened.
- Final review by `/root/design_reviewer`: no Critical or Important findings. Minor deferred: the actual Actions artifact and iLoader import remain unverified until the workflow runs in a user-owned fork.
