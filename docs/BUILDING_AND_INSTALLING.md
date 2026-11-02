# Personal unsigned IPA build and install

This workflow creates an **unsigned** Feather-based iOS IPA. GitHub Actions does not sign it and receives no Apple Account credentials, provisioning profile, `.p12`, or private TLS key. Sign and install the downloaded IPA on your Windows PC with iLoader.

## Build with GitHub Actions

1. Fork this repository into your own GitHub account and push the `feature/personal-unsigned-ipa` branch.
2. Review and merge the branch into your fork's default branch. GitHub only enables `workflow_dispatch` after the workflow file exists on that default branch.
3. Open **Actions → Personal unsigned IPA → Run workflow**.
4. Enter a unique reverse-DNS Bundle ID, such as `com.example.featherpersonal`. Keep the same value for every update; changing it installs a separate app.
5. When the run completes, download `feather-unsigned-ipa-<run number>`. It contains `Feather-unsigned.ipa` and `build-info.txt`.

The workflow uses GitHub's Xcode 27 runner. It only builds the iOS target, disables Xcode code signing, and does not use the existing release workflow. Artifacts expire after 14 days, so keep a local copy of each IPA you may need for recovery.

## Install or update with iLoader on Windows

1. Install iLoader and its documented Apple USB device drivers/iTunes components. Download iLoader from its [official repository](https://github.com/nab138/iloader) and follow its current Windows setup instructions.
2. Connect the iPhone, unlock it, and accept **Trust This Computer** if prompted. Enable Developer Mode if iOS or iLoader requests it.
3. In iLoader, sign in with your Apple Account, import `Feather-unsigned.ipa`, select the connected iPhone, and start signing/installing. Credentials are entered into iLoader on your PC, never into GitHub Actions.
4. For later builds, use the same Bundle ID and iLoader signing account to update the existing installation. Save the IPA locally before replacing it.

iLoader must be able to sign the IPA for your account and device. A free Apple Account uses Apple's limited Personal Team signing allowance and short-lived provisioning; this workflow does not bypass those limits. The build artifact is not itself installable until iLoader signs it.

This personal build leaves Feather's HTTP **Semi Local** install server available, but disables its TLS/“Fully Local” choice because no shared private TLS key is included. Use LocalDevVPN/Pairing for the iPhone-only install path; adding a user-owned TLS identity is outside this first build milestone.

## Scope and source license

This is a personal-use Feather fork targeting iOS 27.0.1 on iPhone 16e. iOS execution, Apple Account signing, and updates must still be confirmed on the actual device. The Feather source is GPL-3.0; preserve its notices and meet the license's source-availability requirements when sharing modified binaries.
