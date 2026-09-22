# SpotiCop

Spotify cop on patrol. Keeps Spotify's runaway cache capped to the limit you set.

<p align="center">
  <img src="macOS/Resources/AppIcon.png" width="128" height="128" alt="SpotiCop Icon" />
</p>

## The Crime

You gave Spotify a monthly subscription, and it decided to move into your SSD rent-free.

Left unattended, Spotify turns your Mac into a landfill of unplayed audio chunks, cached telemetry, and album art from playlists you skipped through three years ago:

- `~/Library/Caches/com.spotify.client`
- `~/Library/Application Support/Spotify/PersistentCache`

Before you know it, a music player is quietly squatting on 20 GB to 40 GB of disk space on a 256 GB drive, with zero native settings to enforce a hard cap.

## The Patrol

SpotiCop enforces a strict storage cap on Spotify's rebuildable cache:

- **Oldest offenders evicted first**: Your heavy rotation tracks stay warm in cache. The 40-minute whale song you played once in 2023 gets shown the door.
- **Zero collateral damage**: Logins, offline playlists, and app preferences are never touched.
- **Peaceful de-escalation**: If Spotify is actively running, SpotiCop stands down so playing audio never skips or crashes.
- **Set and forget**: Runs once a week in the background via launchd, or whenever you tap Patrol Now.

## Installation

### Download

1. Download **[SpotiCop.dmg](https://github.com/yesvus/spoticop/releases/latest)**
2. Drag `SpotiCop` into your `Applications` folder
3. Open it once to choose your cache cap (default: 1 GB)

The app stays in your Dock while settings are open. Closing the window lets it sleep while the background agent patrols on schedule.

### Terminal One-Liner

If you prefer headless CLI and launchd patrols without the GUI:

```sh
curl -fsSL https://raw.githubusercontent.com/yesvus/spoticop/main/install.sh | sh
```

### Build from source

```sh
git clone https://github.com/yesvus/spoticop.git
cd spoticop
./macOS/package.sh
cp -R macOS/build/SpotiCop.app /Applications/
```

## Manual Patrol

Run patrols anytime directly from your terminal:

```sh
spoticop --cap 1GB
```

Or simulate to see what would be evicted without deleting anything:

```sh
spoticop --cap 1GB --dry-run
```

## Acknowledgements

- GUI design inspired by [Mac Mouse Fix](https://github.com/noah-nuebling/mac-mouse-fix).

## License

MIT
