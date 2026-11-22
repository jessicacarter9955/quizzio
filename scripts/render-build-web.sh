#!/usr/bin/env bash
set -euo pipefail

# Install the current stable Flutter SDK in the Render build environment.
RELEASES_JSON="${TMPDIR:-/tmp}/flutter-releases-linux.json"
FLUTTER_ARCHIVE="${TMPDIR:-/tmp}/flutter-linux.tar.xz"
FLUTTER_HOME="${TMPDIR:-/tmp}/flutter-sdk"

curl --fail --silent --show-error --location \
  https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json \
  --output "$RELEASES_JSON"

ARCHIVE_PATH="$(python3 -c '
import json
with open("'"$RELEASES_JSON"'") as f:
    data = json.load(f)
stable_hash = data["current_release"]["stable"]
release = next(item for item in data["releases"] if item["hash"] == stable_hash)
print(release["archive"])
')"

curl --fail --silent --show-error --location \
  "https://storage.googleapis.com/flutter_infra_release/releases/$ARCHIVE_PATH" \
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
