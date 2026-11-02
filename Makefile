NAME := Feather
SCHEME := Feather
PLATFORMS := iphoneos maccatalyst

TMP := $(TMPDIR)/$(NAME)
UNSIGNED_IPA := packages/Feather-unsigned.ipa
export BUNDLE_ID

.PHONY: all clean ipa-unsigned $(PLATFORMS)

all: $(PLATFORMS)

clean:
	rm -rf $(TMP)
	rm -rf packages
	rm -rf Payload

# Personal builds intentionally skip all signing and shared TLS-key setup.
ipa-unsigned:
	@test -n "$$BUNDLE_ID" || (echo "BUNDLE_ID is required (example: com.example.Feather)" >&2; exit 2)
	@python3 -c 'import re,sys; sys.exit(0 if re.fullmatch(r"[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z0-9-]+)+", sys.argv[1]) else 1)' "$$BUNDLE_ID" || (echo "Invalid BUNDLE_ID: use reverse-DNS segments with letters, digits, and hyphens" >&2; exit 2)
	rm -rf _build $(TMP)/unsigned $(UNSIGNED_IPA)
	xcodebuild \
		-project Feather.xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "generic/platform=iOS" \
		-derivedDataPath $(TMP)/unsigned \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		CODE_SIGNING_REQUIRED=NO \
		PRODUCT_BUNDLE_IDENTIFIER="$$BUNDLE_ID" \
		FEATHER_DISAMBIGUATOR=
	test -s _build/Applications/Feather.app/Info.plist
	test -s _build/Applications/Feather.app/Feather
	@! find _build/Applications/Feather.app -name embedded.mobileprovision -print -quit | grep -q .
	mkdir -p _build/Payload packages
	cp -R _build/Applications/Feather.app _build/Payload/Feather.app
	ditto -c -k --sequesterRsrc --keepParent _build/Payload "$(UNSIGNED_IPA)"


$(PLATFORMS):
	rm -rf _build

	@if [ "$@" = "iphoneos" ]; then \
		DEST="generic/platform=iOS"; \
	else \
		DEST="generic/platform=macOS,variant=Mac Catalyst"; \
	fi; \
	xcodebuild \
		-project Feather.xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-destination "$$DEST" \
		-derivedDataPath $(TMP)/$@ \
		-skipPackagePluginValidation \
		CODE_SIGNING_ALLOWED=NO \
		ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO

	mkdir -p _build/Payload
	cp -R _build/Applications/*.app _build/Payload/Feather.app
	chmod -R 0755 _build/Payload/Feather.app
	codesign --force --sign - --timestamp=none _build/Payload/Feather.app

	mkdir -p packages

	@if [ "$@" = "iphoneos" ]; then \
		ditto -c -k --sequesterRsrc --keepParent _build/Payload "packages/Feather.ipa"; \
	else \
		ditto -c -k --sequesterRsrc --keepParent _build/Payload/Feather.app "packages/Feather_Catalyst.zip"; \
	fi
