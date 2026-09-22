#!/bin/sh
set -eu

DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BIN="$DIR/spoticop"

FAILED=0
assert_eq() {
  expected="$1"
  actual="$2"
  label="$3"
  if [ "$expected" != "$actual" ]; then
    echo "FAIL: $label: expected '$expected', got '$actual'" >&2
    FAILED=$((FAILED + 1))
  else
    echo "OK: $label"
  fi
}

TDIR=$(mktemp -d)
trap 'rm -rf "$TDIR"' EXIT

export SPOTICOP_PGREP="false"

C1="$TDIR/cache1"
C2="$TDIR/cache2"
LOG="$TDIR/spoticop.log"
CONF="$TDIR/config"
mkdir -p "$C1" "$C2"

# 1. Under cap test
dd if=/dev/zero of="$C1/a" bs=1024 count=100 2>/dev/null
output=$("$BIN" --cache-a "$C1" --cache-b "$C2" --cap 1MB --log "$LOG" --dry-run)
assert_eq "0" "$?" "exit code when under cap"
echo "$output" | grep -q "within cap"
assert_eq "0" "$?" "under cap message logged"

# 2. Over cap test: oldest deleted first
dd if=/dev/zero of="$C1/old.dat" bs=1024 count=800 2>/dev/null
sleep 1
dd if=/dev/zero of="$C2/new.dat" bs=1024 count=800 2>/dev/null

# Total is 100K (a) + 800K (old) + 800K (new) = 1700K. Cap = 1MB (1024KB). Over cap by ~676KB.
# Dry run should pick the oldest file: old.dat (or a, depending on mtime)
dry_out=$("$BIN" --cache-a "$C1" --cache-b "$C2" --cap 1MB --log "$LOG" --dry-run)
echo "$dry_out" | grep -q "dry run, no files deleted"
assert_eq "0" "$?" "dry run header"
[ -f "$C1/old.dat" ] && [ -f "$C2/new.dat" ]
assert_eq "0" "$?" "dry run did not delete files"

# Now run actual trim
trim_out=$("$BIN" --cache-a "$C1" --cache-b "$C2" --cap 1MB --log "$LOG")
echo "$trim_out" | grep -q "patrol complete"
assert_eq "0" "$?" "patrol complete output"

# Oldest files should have been removed, newest file kept
[ ! -f "$C1/a" ]
assert_eq "0" "$?" "oldest file a was removed"
[ ! -f "$C1/old.dat" ]
assert_eq "0" "$?" "second oldest file old.dat was removed"
[ -f "$C2/new.dat" ]
assert_eq "0" "$?" "newest file new.dat kept"

# 3. Spotify running test
SPOTICOP_PGREP="true"
run_out=$("$BIN" --cache-a "$C1" --cache-b "$C2" --cap 1MB --log "$LOG")
echo "$run_out" | grep -q "Spotify is running, skipping patrol"
assert_eq "0" "$?" "skipped when spotify running"
SPOTICOP_PGREP="false"

# 4. Config file parsing test
mkdir -p "$(dirname "$CONF")"
cat <<EOF >"$CONF"
CAP = 500MB
LOG = $TDIR/custom.log
DRY_RUN = 1
EOF

conf_out=$("$BIN" --config "$CONF" --cache-a "$C1" --cache-b "$C2")
assert_eq "0" "$?" "config load exit 0"
echo "$conf_out" | grep -q "within cap"
assert_eq "0" "$?" "ran with config cap"

# 5. Protected directories and files test
PDIR="$TDIR/protected_test"
mkdir -p "$PDIR/Update" "$PDIR/Users/profile/primary.ldb" "$PDIR/data"
dd if=/dev/zero of="$PDIR/Update/spotify-autoupdate.tbz" bs=1024 count=400 2>/dev/null
dd if=/dev/zero of="$PDIR/Users/profile/primary.ldb/000001.ldb" bs=1024 count=400 2>/dev/null
dd if=/dev/zero of="$PDIR/index.dat" bs=1024 count=100 2>/dev/null
dd if=/dev/zero of="$PDIR/settings.json" bs=1024 count=100 2>/dev/null
sleep 1
dd if=/dev/zero of="$PDIR/data/track1.file" bs=1024 count=800 2>/dev/null
sleep 1
dd if=/dev/zero of="$PDIR/data/track2.file" bs=1024 count=800 2>/dev/null

# Total is 400 + 400 + 100 + 100 + 800 + 800 = 2600KB. Cap is 2MB (2048KB).
# Non-protected files: track1.file is older than track2.file.
# Protected files are oldest, but must never be touched.
# track1.file (800KB) should be deleted, bringing total to 1800KB (under 2048KB cap).
# track2.file should be kept.
prot_out=$("$BIN" --cache-a "$PDIR" --cache-b "$PDIR" --cap 2MB --log "$LOG")
assert_eq "0" "$?" "protected test exit 0"
[ -f "$PDIR/Update/spotify-autoupdate.tbz" ]
assert_eq "0" "$?" "Update directory files protected"
[ -f "$PDIR/Users/profile/primary.ldb/000001.ldb" ]
assert_eq "0" "$?" "Users and ldb files protected"
[ -f "$PDIR/index.dat" ]
assert_eq "0" "$?" "index.dat protected"
[ -f "$PDIR/settings.json" ]
assert_eq "0" "$?" "json files protected"
[ ! -f "$PDIR/data/track1.file" ]
assert_eq "0" "$?" "unprotected track1.file was removed"
[ -f "$PDIR/data/track2.file" ]
assert_eq "0" "$?" "track2.file kept"

# 6. Auto-subpath normalization test
NORM_DIR="$TDIR/norm"
mkdir -p "$NORM_DIR/com.spotify.client/Data" "$NORM_DIR/PersistentCache/Storage"
touch "$NORM_DIR/com.spotify.client/Data/track.file"
touch "$NORM_DIR/PersistentCache/Storage/track.file"
norm_out=$("$BIN" --cache-a "$NORM_DIR/com.spotify.client" --cache-b "$NORM_DIR/PersistentCache" --cap 1MB --log "$LOG" --dry-run)
assert_eq "0" "$?" "normalization run exit 0"
echo "$norm_out" | grep -q "within cap"
assert_eq "0" "$?" "normalized to Data and Storage subpaths"

if [ "$FAILED" -gt 0 ]; then
  echo "Tests failed: $FAILED" >&2
  exit 1
fi

echo "All tests passed."
