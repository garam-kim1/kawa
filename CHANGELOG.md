## Unreleased

* Fix CJKV (Chinese/Japanese/Korean/Vietnamese) switching not engaging the
  input method in browsers and Electron apps (e.g. Slack in a web browser):
  the menu-bar indicator changed but typing stayed in the previous layout.
  Kawa now briefly takes focus with an invisible window so the IME activates,
  then restores focus. Technique adapted from `laishulu/macism`; replaces the
  old "select previous input source" hotkey workaround, which no longer works
  on recent macOS.
* The focus-hold time defaults to 50 ms and is configurable (no UI) via
  `defaults write net.noraesae.Kawa ime-activation-delay-ms <ms>` — lower it
  if a fast first keystroke gets swallowed, raise it if switching doesn't take.
* Suppress the preferences window flashing open during the CJKV focus nudge.

## 1.1.0 (10 Nov 2017)

* Remove previous notifications on new one (#17)

## 1.0.1 (18 Sep 2017)

* Make statusbar icon visible in dark UI

## 1.0.0 (16 Sep 2017)

* Add an option to show macOS notification on source change (#9)
* Implement a proper workaround for the known CJKV bug (#12)
* Update licenses for 2017
* Minor code refactoring

## 0.1.3 (3 Oct 2016)

* Use Swift 3
* Remove 'advanced input switching'

## 0.1.2 (6 Aug 2015)

* Change 'simple method' option to 'advanced method' option.
* Open 'Preferences' initially only for the first launch.

## 0.1.0 (6 Aug 2015)

* Initial release
