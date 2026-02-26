#!/usr/bin/env bash
set -euo pipefail

# Script location → ReactApp root
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RNLIB_BUILD_FILE="$ROOT_DIR/android/rnlib/build.gradle.kts"
HOST_LIBS_VERSIONS="$ROOT_DIR/../Host/gradle/libs.versions.toml"

echo "Using rnlib build file: $RNLIB_BUILD_FILE"

# 1) Read current rnlib version from Maven publication in build.gradle.kts
#    This extracts only the value inside the quotes after `version = "..."`.
#    Note: use POSIX character classes (BSD/macOS grep/sed don't support \s).
CURRENT_VERSION="$(
  grep -Eo 'version[[:space:]]*=[[:space:]]*"[^"]+"' "$RNLIB_BUILD_FILE" \
    | head -n 1 \
    | sed -E 's/.*"([^"]+)".*/\1/'
)"

if [[ -z "$CURRENT_VERSION" ]]; then
  echo "ERROR: Could not extract version from $RNLIB_BUILD_FILE" >&2
  exit 1
fi

echo "Current rnlib version: $CURRENT_VERSION"

# 2) Increment last numeric component in version (supports 0.0.x, 0.0.x-SNAPSHOT, etc.)
BASE_NUMERIC="$(sed -E 's/^([0-9]+(\.[0-9]+)*).*/\1/' <<< "$CURRENT_VERSION")"
SUFFIX="${CURRENT_VERSION#$BASE_NUMERIC}"

IFS='.' read -ra PARTS <<< "$BASE_NUMERIC"
LAST_IDX=$(( ${#PARTS[@]} - 1 ))
PATCH="${PARTS[$LAST_IDX]}"

if ! [[ "$PATCH" =~ ^[0-9]+$ ]]; then
  echo "ERROR: Last component '$PATCH' is not numeric in version '$CURRENT_VERSION'" >&2
  exit 1
fi

PATCH=$((PATCH + 1))
PARTS[$LAST_IDX]="$PATCH"
NEW_BASE_NUMERIC="$(IFS='.'; echo "${PARTS[*]}")"
NEW_VERSION="${NEW_BASE_NUMERIC}${SUFFIX}"

echo "Bumping rnlib version to: $NEW_VERSION"

# 3) Update version in android/rnlib/build.gradle.kts
sed -i '' -E "s/(version[[:space:]]*=[[:space:]]*\")${CURRENT_VERSION}(\".*)/\1${NEW_VERSION}\2/" "$RNLIB_BUILD_FILE"

# Verify the file was actually updated (sed exits 0 even if no substitution occurred).
UPDATED_VERSION="$(
  grep -Eo 'version[[:space:]]*=[[:space:]]*"[^"]+"' "$RNLIB_BUILD_FILE" \
    | head -n 1 \
    | sed -E 's/.*"([^"]+)".*/\1/'
)"
if [[ "$UPDATED_VERSION" != "$NEW_VERSION" ]]; then
  echo "ERROR: build.gradle.kts was not updated (expected '$NEW_VERSION', found '$UPDATED_VERSION')." >&2
  exit 1
fi

echo "Updated rnlib version in $RNLIB_BUILD_FILE"

# 4) Publish to local Maven repo
echo "Publishing rnlib to local Maven..."
(
  cd "$ROOT_DIR/android"
  ./gradlew rnlib:publishMavenAarPublicationToMavenLocal
)

echo "Publish finished."

# 5) Update Host/ gradle/libs.versions.toml
if [[ -f "$HOST_LIBS_VERSIONS" ]]; then
  echo "Updating rnlib version in $HOST_LIBS_VERSIONS"

  # Update only the [versions] entry like: rnlib = "0.0.16"
  sed -i '' -E "s/^([[:space:]]*rnlib[[:space:]]*=[[:space:]]*\")[^\"]+(\")/\1${NEW_VERSION}\2/" "$HOST_LIBS_VERSIONS"

  # Verify update happened (fail fast if not).
  HOST_RNLIB_VERSION="$(
    grep -E '^[[:space:]]*rnlib[[:space:]]*=' "$HOST_LIBS_VERSIONS" \
      | head -n 1 \
      | sed -E 's/^[[:space:]]*rnlib[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/'
  )"
  if [[ "$HOST_RNLIB_VERSION" != "$NEW_VERSION" ]]; then
    echo "ERROR: libs.versions.toml was not updated (expected '$NEW_VERSION', found '$HOST_RNLIB_VERSION')." >&2
    exit 1
  fi

  echo "Updated rnlib entry in libs.versions.toml to $NEW_VERSION"
else
  echo "WARNING: Host libs.versions.toml not found at $HOST_LIBS_VERSIONS; skipping update." >&2
fi

echo "Done. New rnlib version: $NEW_VERSION"
