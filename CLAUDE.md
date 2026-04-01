# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Does

`clipboard-normalizer` is a macOS menu-bar-less background utility that converts clipboard images to PNG whenever the user switches focus to a terminal application. It solves the problem that Claude Code (and other terminal-based tools) can only read PNG images from the clipboard — not TIFF, JPEG, or BMP, which macOS apps like WeChat often write.

The tool is event-driven (zero polling): it hooks into `NSWorkspace.didActivateApplicationNotification` and only runs when focus moves to a known terminal bundle ID.

## Build & Install

```bash
# Compile + install as a LaunchAgent (runs on login, restarts if it crashes)
./setup.sh

# Uninstall
./teardown.sh
```

`install.sh` does three things: compiles the Swift source to `./clipboard-normalizer`, patches the plist with the real install path, and loads it via `launchctl`.

To compile manually without installing:
```bash
swiftc clipboard-normalizer.swift -o clipboard-normalizer
```

## Logs

```bash
tail -f /tmp/clipboard-normalizer.log
```

The process logs to stderr (redirected by the LaunchAgent to `/tmp/clipboard-normalizer.log`). Each PNG conversion prints a timestamped line with the resulting byte count.

## Architecture

Single-file Swift program (`clipboard-normalizer.swift`):

- **`TERMINAL_BUNDLE_IDS`** — set of bundle IDs to watch. Add new terminals here.
- **`tryConvertToPNG()`** — reads `NSPasteboard.general`, skips if PNG already present, otherwise converts via `NSImage` → TIFF → `NSBitmapImageRep` → PNG and writes back.
- **`NSWorkspace.didActivateApplicationNotification` observer** — fires on every app-switch; `tryConvertToPNG()` is called only when the newly active app is in `TERMINAL_BUNDLE_IDS`.
- **`RunLoop.main.run()`** — keeps the process alive, blocking on the main run loop.

The LaunchAgent plist sets `KeepAlive = true` so launchd restarts the process if it exits.

## Adding a New Terminal

Edit `TERMINAL_BUNDLE_IDS` in `clipboard-normalizer.swift`, then run `./install.sh` to recompile and reload.
