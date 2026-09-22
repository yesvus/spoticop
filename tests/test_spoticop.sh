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
export SPOTICOP_PGREP="true"
run_out=$("$BIN" --cache-a "$C1" --cache-b "$C2" --cap 1MB --log "$LOG")
echo "$run_out" | grep -q "Spotify is running, skipping patrol"
assert_eq "0" "$?" "skipped when spotify running"
unset SPOTICOP_PGREP

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

if [ "$FAILED" -gt 0 ]; then
  echo "Tests failed: $FAILED" >&2
  exit 1
fi

echo "All tests passed."
