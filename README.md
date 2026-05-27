![logo](resource/png/logo.png)

# Kawa (modernized fork)

A macOS input source switcher with user-defined shortcuts.

> **This is a maintenance fork of [utatti/kawa](https://github.com/utatti/kawa).**
> The upstream project hasn't been updated in years and stopped working on
> recent macOS releases (the global-hotkey library it depended on,
> [`MASShortcut`](https://github.com/shpakovski/MASShortcut), has been
> archived). This fork modernizes the codebase for current macOS:
>
> - Replaces Carthage + the archived MASShortcut framework with
>   [`sindresorhus/KeyboardShortcuts`](https://github.com/sindresorhus/KeyboardShortcuts)
>   via Swift Package Manager.
> - Replaces the deprecated `NSUserNotification` with
>   `UNUserNotificationCenter`.
> - Bumps the deployment target to **macOS 13 (Ventura)** and drops other
>   deprecated APIs.
> - Enables Hardened Runtime, adds an explicit entitlements file, and
>   tightens unsafe force-casts.
> - Fixes an upstream UI bug where the Preferences tab was unreachable
>   (the tab bar was hidden).
> - Adds a unit test target.

## Requirements

- macOS 13 (Ventura) or later
- Xcode 16 or later (for building)

## Install

This fork doesn't ship prebuilt binaries — you'll need to build from source.

### 1. Get the source and build

```bash
git clone <this-fork-url> kawa
cd kawa
xcodebuild -project kawa.xcodeproj \
  -scheme kawa \
  -configuration Release \
  -derivedDataPath build/DerivedData \
  -skipMacroValidation \
  build
```

If the build succeeds you'll see `** BUILD SUCCEEDED **` near the end and the
app will be at `build/DerivedData/Build/Products/Release/Kawa.app`.

First build takes 1–2 minutes (Swift Package Manager fetches
`KeyboardShortcuts` from GitHub). Subsequent builds are seconds.

### 2. Copy into /Applications

```bash
cp -R build/DerivedData/Build/Products/Release/Kawa.app /Applications/
```

### 3. First launch (Gatekeeper)

Because the binary is **ad-hoc signed** (no Apple Developer ID), macOS
blocks it on first launch. On recent macOS the old "right-click → Open"
trick no longer offers an **Open** button — you need to allow it
explicitly:

```bash
open /Applications/Kawa.app
```

You'll see *"Kawa cannot be opened because the developer cannot be
verified."* Click **Done**, then:

1. Open **System Settings → Privacy & Security**.
2. Scroll to the bottom. You'll see *"Kawa was blocked from use because
   it is not from an identified developer."*
3. Click **Open Anyway**, authenticate.
4. A confirmation dialog appears — click **Open**.

This is a one-time prompt per build. Subsequent launches are silent.

### 4. Grant Accessibility permission

Global keyboard shortcuts require Accessibility access (this is how
macOS lets a background app receive keypresses while other apps are
focused). Either let macOS prompt on first hotkey use, or grant it now:

1. **System Settings → Privacy & Security → Accessibility**.
2. Click **+**, navigate to `/Applications/Kawa.app`, **Open**.
3. Toggle the switch **on** for Kawa.

### 5. Verify

Look at the macOS menu bar (top-right corner). You should see Kawa's
icon. Click it to open the preferences window.

- **Shortcuts** tab — click a recorder, press the key combo you want
  for each input source.
- **Preferences** tab — toggle "Show notification on input source
  change" if you want a banner each switch.

Press a recorded shortcut from any app to confirm your input source
changes.

## Upgrading from the old version

If you previously used the original [utatti/kawa](https://github.com/utatti/kawa)
(or a Homebrew cask install from before this fork), do this **before**
installing the new build:

### 1. Quit the old Kawa

```bash
osascript -e 'tell application "Kawa" to quit' 2>/dev/null
pkill -x Kawa 2>/dev/null
```

Either succeeds silently; both together guarantee Kawa is no longer
running.

### 2. Remove the old app

```bash
rm -rf /Applications/Kawa.app
```

If you originally installed via Homebrew Cask:

```bash
brew uninstall --cask kawa 2>/dev/null || true
```

### 3. Wipe the old shortcut bindings (required)

The upstream version stored shortcuts in `MASShortcut`'s archived binary
format; this fork uses `KeyboardShortcuts`' JSON format. The two are not
interoperable, so the old data is unreadable and must be cleared:

```bash
defaults delete net.noraesae.Kawa 2>/dev/null
defaults read net.noraesae.Kawa 2>&1 | head -3
```

The `read` should print *"Domain ... does not exist"* — that confirms
the wipe worked.

Your macOS input sources themselves (added in **System Settings →
Keyboard → Text Input → Edit…**) are unaffected — only the
Kawa-side shortcut assignments need to be re-set.

### 4. Install the new build

Follow the [Install](#install) section above.

### 5. Re-record your shortcuts

Old bindings can't be migrated automatically. Open Kawa's preferences
(click the menu-bar icon) and set each shortcut again.

## Caveats

### CJKV input sources

macOS has a long-standing quirk: switching *to* a complex, IME-backed
[CJKV](https://en.wikipedia.org/wiki/CJK_characters) source (Chinese,
Japanese, Korean, Vietnamese) with `TISSelectInputSource` often only updates
the menu-bar indicator without actually activating the input method in the
focused app. The language *looks* switched but typing still produces the
previous layout (usually plain English) — most noticeably in browsers and
Electron apps such as **Slack in a web browser**, VS Code, etc.

Kawa works around this (technique adapted from
[`laishulu/macism`](https://github.com/laishulu/macism)): when you switch to
a CJKV source, it briefly takes focus with a tiny invisible window so the IME
engages, then hands focus back to the app you were typing in. The only visible
effect is a brief focus flicker, and only when switching to a CJKV source —
switching to Latin layouts (ABC/U.S. etc.) is unaffected.

#### Tuning the focus-hold time

The window is held for **50 ms** by default. While it's held, keystrokes go to
Kawa, so if you start typing extremely quickly after switching, the first
letter can be swallowed — shorten the hold. If switching instead leaves you
typing in the previous layout, the IME didn't finish engaging — lengthen it.
There's no UI; set it (in milliseconds) and restart Kawa:

```bash
defaults write net.noraesae.Kawa ime-activation-delay-ms 30
```

Newer macOS (e.g. macOS 26 Tahoe) tends to need a larger value (~150 ms) than
older releases (which manage with just a few ms).

## Development

Dependencies are managed via **Swift Package Manager**, integrated
directly into the Xcode project — no extra setup required.

```bash
git clone <this-fork-url>
open kawa.xcodeproj
```

Xcode resolves packages automatically on first open.

### Tests

```bash
xcodebuild -project kawa.xcodeproj -scheme kawa \
  -derivedDataPath build/DerivedData \
  -skipMacroValidation \
  test
```

## License

Kawa is released under the [MIT License](LICENSE). Original work
copyright the upstream project's contributors; modernization changes
copyright their respective authors, all under the same MIT terms.
