#!/usr/bin/env bash
set -euo pipefail

# Install the current stable Flutter SDK in the Render build environment.
RELEASES_JSON="${TMPDIR:-/tmp}/flutter-releases-linux.json"
FLUTTER_ARCHIVE="${TMPDIR:-/tmp}/flutter-linux.tar.xz"
FLUTTER_HOME="${TMPDIR:-/tmp}/flutter-sdk"

echo "Fetching Flutter stable release metadata..."
curl --fail --silent --show-error --location \
  "https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json" \
  --output "$RELEASES_JSON"

FLUTTER_DOWNLOAD_URL="$(
  python3 - "$RELEASES_JSON" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as releases_file:
    data = json.load(releases_file)

stable_hash = data["current_release"]["stable"]
release = next(item for item in data["releases"] if item["hash"] == stable_hash)
archive = release["archive"]

if archive.startswith(("https://", "http://")):
    print(archive)
else:
    base_url = data.get(
        "base_url",
        "https://storage.googleapis.com/flutter_infra_release/releases",
    ).rstrip("/")
    print(f"{base_url}/{archive.lstrip('/')}")
PY
)"

if [[ -z "$FLUTTER_DOWNLOAD_URL" ]]; then
  echo "Could not resolve the latest stable Flutter SDK download URL." >&2
  exit 1
fi

echo "Downloading Flutter SDK from: $FLUTTER_DOWNLOAD_URL"
curl --fail --silent --show-error --location \
  "$FLUTTER_DOWNLOAD_URL" \
  --output "$FLUTTER_ARCHIVE"

mkdir -p "$FLUTTER_HOME"
tar -xf "$FLUTTER_ARCHIVE" -C "$FLUTTER_HOME"
export PATH="$FLUTTER_HOME/flutter/bin:$PATH"

flutter config --no-analytics
flutter --version
flutter pub get
flutter analyze --no-fatal-warnings --no-fatal-infos
flutter test
flutter build web --release --base-href /
