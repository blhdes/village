#!/usr/bin/env bash
# Pushes VILLE's App Store Connect setup from the files in store/.
#
#   bash store/apply-store-setup.sh          # dry run: prints every command, changes nothing
#   bash store/apply-store-setup.sh --go     # really sends them (only after Ale's OK in chat)
#
# Fill the variables marked DECIDE first. Sections whose inputs are still DECIDE are skipped.
# Every value here comes from store/METADATA.md (the reasons live there).

set -euo pipefail
cd "$(dirname "$0")/.."

APP_ID="6829207754"
VERSION="1.0"
VERSION_ID="7712a8d8-4ee9-4ffc-a6ed-f4f282b1d949"   # from: asc versions list --app 6829207754

COPYRIGHT="2026 Alejandro Gómez Urrea"
PRIMARY_CATEGORY="ENTERTAINMENT"
SECONDARY_CATEGORY="LIFESTYLE"           # Ale's choice, 2026-10-31

# The in-app Google search (tap a film title) opens Safari inside the app, so the honest answer
# is yes (Ale's choice, 2026-10-31). It raises the age rating.
UNRESTRICTED_WEB_ACCESS="true"

# App Review contact. Apple only shows it to the review team. The repo is public, so the
# email and phone live in store/contact.env (gitignored), e.g.:
#   CONTACT_EMAIL="you@example.com"
#   CONTACT_PHONE="+34 600 000 000"
CONTACT_FIRST_NAME="Alejandro"
CONTACT_LAST_NAME="Gómez Urrea"
CONTACT_EMAIL="DECIDE"
CONTACT_PHONE="DECIDE"
# shellcheck disable=SC1091
[ -f store/contact.env ] && source store/contact.env

GO=false
[ "${1:-}" = "--go" ] && GO=true

run() {
  printf '  $'; printf ' %q' "$@"; printf '\n'
  if $GO; then "$@"; fi
}
section() { printf '\n== %s\n' "$1"; }
skip() { printf '\n== %s\n  (skipped: %s)\n' "$1" "$2"; }

$GO && echo "Sending to App Store Connect…" || echo "Dry run. Nothing is sent. Re-run with --go after the OK."

section "Product page text (name, subtitle, description, keywords, promo, support and privacy URLs) for en-US and es-ES"
asc metadata validate --dir store/metadata >/dev/null
if $GO; then
  run asc metadata apply --app "$APP_ID" --version "$VERSION" --dir store/metadata
else
  run asc metadata apply --app "$APP_ID" --version "$VERSION" --dir store/metadata --dry-run
fi

section "Categories"
if [ -n "$SECONDARY_CATEGORY" ]; then
  run asc categories set --app "$APP_ID" --primary "$PRIMARY_CATEGORY" --secondary "$SECONDARY_CATEGORY"
else
  run asc categories set --app "$APP_ID" --primary "$PRIMARY_CATEGORY"
fi

section "Copyright, and manual release (you pick launch day after approval)"
run asc versions update --version-id "$VERSION_ID" --copyright "$COPYRIGHT" --release-type MANUAL

section "Price: free (starts today, Pacific time)"
run asc pricing schedule create --app "$APP_ID" --free --base-territory "US"

section "Availability: every country except China mainland (it needs an ICP filing number)"
run asc pricing availability create --app "$APP_ID" --all-territories --available true --available-in-new-territories true
run asc pricing availability edit --app "$APP_ID" --territory "CHN" --available false

if [ "$UNRESTRICTED_WEB_ACCESS" = "DECIDE" ]; then
  skip "Age rating" "decide UNRESTRICTED_WEB_ACCESS first"
else
  section "Age rating (other people's reviews may mention anything, mildly)"
  run asc age-rating edit --app "$APP_ID" \
    --advertising false --age-assurance false --gambling false --health-or-wellness-topics false \
    --loot-box false --messaging-and-chat false --parental-controls false \
    --social-media false --social-media-age-restricted false \
    --user-generated-content true --unrestricted-web-access "$UNRESTRICTED_WEB_ACCESS" \
    --alcohol-tobacco-drug-use INFREQUENT_OR_MILD --contests NONE --gambling-simulated NONE \
    --guns-or-other-weapons NONE --horror-fear INFREQUENT_OR_MILD --mature-suggestive INFREQUENT_OR_MILD \
    --medical-treatment NONE --profanity-humor INFREQUENT_OR_MILD \
    --sexual-content-graphic-nudity NONE --sexual-content-nudity INFREQUENT_OR_MILD \
    --violence-cartoon NONE --violence-realistic INFREQUENT_OR_MILD --violence-realistic-graphic NONE
fi

if [ "$CONTACT_EMAIL" = "DECIDE" ] || [ "$CONTACT_PHONE" = "DECIDE" ]; then
  skip "App Review details (contact + notes)" "put CONTACT_EMAIL and CONTACT_PHONE in store/contact.env first"
else
  section "App Review details: no sign-in, contact, notes (text in store/review-notes.txt)"
  run asc review details-create --version-id "$VERSION_ID" \
    --contact-first-name "$CONTACT_FIRST_NAME" --contact-last-name "$CONTACT_LAST_NAME" \
    --contact-email "$CONTACT_EMAIL" --contact-phone "$CONTACT_PHONE" \
    --demo-account-required=false --notes "@file:store/review-notes.txt" --if-exists update
fi

skip "Content rights (uses third-party content)" "waits for Letterboxd's answer (RELEASE.md, Risks 1). Then: asc apps content-rights edit --app $APP_ID --uses-third-party-content true"
skip "App Privacy (Data Not Collected)" "not in the public API: set it in App Store Connect → App Privacy, in Chrome"
skip "Screenshots" "phase 4"
skip "Build" "phase 5"

printf '\nAfterwards: asc validate --app %s --version %s\n' "$APP_ID" "$VERSION"
