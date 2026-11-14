# Set up SpotiCop with a coding agent

Paste this into ChatGPT Work, Codex, OpenCode, Claude Code or Cursor:

~~~text
Help me install SpotiCop, the macOS Spotify cache manager:
https://github.com/yesvus/spoticop

Goal: configure it safely without deleting any Spotify cache until
I have reviewed the targets and explicitly approved a real cleanup.

1. Read the current README.md, INSTALL_PROMPT.md and actual install.sh
   source before choosing installation commands.
2. Verify this is macOS and check CPU architecture, existing Spotify,
   SpotiCop installation, LaunchAgent configuration and available disk.
3. Prefer the official GitHub release .dmg for a GUI installation.
   Verify the release and publisher; don't silently run curl | sh.
   If I prefer CLI, inspect the repository installer first and get consent.
4. Explain the cache path(s) it can touch. Run a documented dry run,
   using spoticop --cap 1GB --dry-run, after installing the CLI.
5. Show the estimated eviction results, confirm that offline Spotify
   downloads and application preferences are out of scope as documented.
6. Ask me separately before real deletion, scheduled launchd activation
   or changing the cache size. Do not kill Spotify during playback.
7. Report the installed version, verification, scheduled jobs (if any),
   and uninstall/rollback instructions.

Never request account secrets, modify Spotify databases or messages,
erase arbitrary directories, use sudo without approval or promise a
specific amount of recoverable APFS space without measuring it.
~~~

The script is an onboarding instruction, not an alternative installer.
See [manual installation](README.md#installation).
