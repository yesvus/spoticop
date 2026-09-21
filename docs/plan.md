# plan

## Problem

Spotify refills disk with rebuildable cache. Measured on zombie 2026-09-22:

- `~/Library/Caches/com.spotify.client` 545M
- `~/Library/Application Support/Spotify/PersistentCache` 1.4G
- `Users`, `prefs` tiny, never touched

## Core: cache trimming

This is the whole product. A script enforces a 1GB cap over both cache dirs:

- measure both dirs, if total over cap trim oldest files first down to cap
- oldest-first keeps fresh artwork and audio, evicts what has not been played
- never touch `Users`, `prefs`, or anything outside the two cache dirs
- if Spotify is running, skip the run and log it, never delete open files
- log every run with before/after sizes to `~/Library/Logs/spotcop.log`
- support `--dry-run` printing what would be deleted without deleting

## Schedule

- weekly launchd agent on zombie, Sundays 04:00, `~/Library/LaunchAgents`
- no daemon, no GUI, exits after one pass

## Ship

1. script + launchd plist + README with install one-liner, MIT license
2. dry-run on zombie, then one live run with Spotify closed, verify sizes and log
3. publish to GitHub, install on zombie from the repo
