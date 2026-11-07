#!/bin/bash
# VILLE store screenshots, step 1 of 2: the raw captures, on the iPhone.
#
# Runs the VILLEStoreShots UI test on the connected iPhone once per language
# and saves each screen as store/screenshots/raw/<language>/<shot>.png.
# Step 2 is `kou generate store/screenshots/koubou.yaml`.
#
# Usage (from anywhere):
#   store/screenshots/capture.sh                 # dry run: shows what it would do
#   store/screenshots/capture.sh --go            # all eight languages
#   store/screenshots/capture.sh --go es-ES ja   # only these
#
# Needs: the iPhone connected and unlocked, Developer Mode on,
# Settings → Developer → Enable UI Automation on. Never the simulator.
# The iPhone is found with devicectl; set UDID=… to pick one. Its ID is never
# written to a file (the repo can be public). SCHEME=… if the test target
# isn't in the VILLE scheme.

set -euo pipefail
cd "$(dirname "$0")/../.."

go=false
languages=()
for argument in "$@"; do
  case "$argument" in
    --go) go=true ;;
    *) languages+=("$argument") ;;
  esac
done
[ ${#languages[@]} -eq 0 ] && languages=(en-US es-ES de-DE fr-FR it ja pt-BR zh-Hans)

scheme="${SCHEME:-VILLE}"
raw="store/screenshots/raw"

# App Store locale → the language and region the app runs in.
settings_for() {
  case "$1" in
    en-US) echo "en US" ;;
    es-ES) echo "es ES" ;;
    de-DE) echo "de DE" ;;
    fr-FR) echo "fr FR" ;;
    it) echo "it IT" ;;
    ja) echo "ja JP" ;;
    pt-BR) echo "pt-BR BR" ;;
    zh-Hans) echo "zh-Hans CN" ;;
    *) echo "capture.sh: unknown language $1" >&2; exit 1 ;;
  esac
}

find_iphone() {
  local list
  list="$(mktemp)"
  xcrun devicectl list devices --json-output "$list" >/dev/null
  python3 -I - "$list" <<'PY'
import json, sys
devices = json.load(open(sys.argv[1]))["result"]["devices"]
# Only a real iPhone, never a simulator.
phones = [d for d in devices
          if d.get("hardwareProperties", {}).get("platform") == "iOS"
          and d.get("hardwareProperties", {}).get("deviceType") == "iPhone"
          and d.get("hardwareProperties", {}).get("reality") == "physical"]
if not phones:
    sys.exit("capture.sh: no physical iPhone paired with this Mac")
print(phones[0]["hardwareProperties"]["udid"])
PY
  rm -f "$list"
}

udid="${UDID:-}"
if [ -z "$udid" ]; then
  udid="$(find_iphone)"
fi

echo "iPhone: found (ID kept out of files). Scheme: $scheme"
for locale in "${languages[@]}"; do
  read -r language region <<<"$(settings_for "$locale")"
  echo "· $locale: VILLE in $language ($region), 7 shots → $raw/$locale/"
done
if ! $go; then
  echo "Dry run. Add --go to install the test runner on the iPhone and capture."
  exit 0
fi

for locale in "${languages[@]}"; do
  read -r language region <<<"$(settings_for "$locale")"
  result="$raw/$locale.xcresult"
  rm -rf "$result" "$raw/$locale"
  mkdir -p "$raw/$locale"

  echo "== $locale"
  xcodebuild test \
    -project VILLE/VILLE.xcodeproj \
    -scheme "$scheme" \
    -only-testing:VILLEStoreShots \
    -destination "platform=iOS,id=$udid" \
    -testLanguage "${language%%-*}" -testRegion "$region" \
    -resultBundlePath "$result" \
    TEST_RUNNER_STORE_LANGUAGE="$language" \
    TEST_RUNNER_STORE_REGION="$region" \
    | grep -E "error:|Test Case|\*\* TEST" || true

  # The attachments come out with generated names; the manifest maps them
  # back to the shot names the test gave them.
  export_dir="$(mktemp -d)"
  xcrun xcresulttool export attachments --path "$result" --output-path "$export_dir" >/dev/null
  python3 -I - "$export_dir" "$raw/$locale" <<'PY'
import json, re, shutil, sys
source, target = sys.argv[1], sys.argv[2]
saved = 0
for test in json.load(open(f"{source}/manifest.json")):
    for attachment in test["attachments"]:
        match = re.match(r"\d-[a-z]+", attachment.get("suggestedHumanReadableName", ""))
        if match:
            shutil.copy(f"{source}/{attachment['exportedFileName']}", f"{target}/{match.group(0)}.png")
            saved += 1
print(f"   {saved} captures saved")
if saved != 7:
    sys.exit(f"capture.sh: expected 7 captures, got {saved}")
PY
  rm -rf "$export_dir"
done

echo "Done. Check the captures, then: kou generate store/screenshots/koubou.yaml"
