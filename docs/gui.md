# gui

Simple native macOS app in the spirit of tiny utilities: one settings window, otherwise invisible.

- agent app (`LSUIElement`), no Dock icon, no menubar icon, runs in background
- settings window: cap size (default 1GB), weekly day/time, dry-run toggle, run-now button, log viewer, watched paths
- opens via Spotlight or Applications, closing the window returns it to background
- trim core stays headless so launchd and CLI work without the GUI, GUI only edits prefs and triggers runs
- README gets a screenshot of the settings window
