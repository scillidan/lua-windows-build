#!/usr/bin/env bash
set -euo pipefail

SRCDIR="$1"
BASEURL_LUA="https://www.lua.org/ftp"
BASEURL_LUAROCKS="https://luarocks.github.io/luarocks/releases"

declare -A SOURCES=(
  [lua]="$BASEURL_LUA"
  [luarocks]="$BASEURL_LUAROCKS"
)

declare -A FILES=(
  [lua]="lua-5.4.8.tar.gz"
  [luarocks]="luarocks-3.13.0-windows-64.zip"
)

if [ -z "$SRCDIR" ]; then
  echo "Usage: $0 <src_dir> [lua|luarocks|all]"
  exit 1
fi

mkdir -p "$SRCDIR"

CHECKSUM_FILE="$(cd "$(dirname "$0")" && pwd)/checksums.sha256"

_expect_hash() {
  local f="$1"
  grep -i "$(printf '%s' "$f" | sed 's/[.\-]/[.\-]/g')" "$CHECKSUM_FILE" | head -1 | awk '{print tolower($1)}'
}

check_file() {
  local f="$1"
  local actual expected
  actual=$(sha256sum "$SRCDIR/$f" | awk '{print $1}')
  expected=$(_expect_hash "$f")
  [ "$actual" = "$expected" ]
}

download() {
  local kind="$1" baseurl="$2"
  local f="${FILES[$kind]}"
  echo "==> Checking $f"
  if [ -f "$SRCDIR/$f" ] && check_file "$f"; then
    echo "    hash OK, skip"
    return
  fi
  [ -f "$SRCDIR/$f" ] && echo "    hash mismatch, removing" && rm -f "$SRCDIR/$f"
  echo "    downloading $baseurl/$f"
  if ! curl -L --fail "$baseurl/$f" -o "$SRCDIR/$f"; then
    echo
    echo "Download failed!"
    echo "Please manually download:"
    echo "  $baseurl/$f"
    echo "Into:"
    echo "  $SRCDIR/"
    exit 1
  fi
  if ! check_file "$f"; then
    echo "Hash verification failed after download"
    exit 1
  fi
}

ACTION="${2:-all}"

case "$ACTION" in
  lua)      download lua "${SOURCES[lua]}" ;;
  luarocks) download luarocks "${SOURCES[luarocks]}" ;;
  all)      download lua "${SOURCES[lua]}"
            download luarocks "${SOURCES[luarocks]}" ;;
  *)        echo "Usage: $0 <src_dir> [lua|luarocks|all]"; exit 1 ;;
esac

echo "All sources ready in $SRCDIR"
