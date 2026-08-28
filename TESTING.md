# TESTING.md — acceptance checklist for the test machine

All acceptance testing happens on a dedicated test machine, never on the dev machine.
Run every phase in order. Each step lists the command, what success looks like, and
what to capture if it fails. If any step fails: capture the output, stop, and bring
it back to the drawing board — do not hand-fix the test machine.

## 0. Preconditions

- [ ] Machine has Homebrew installed and working: `brew --version`
- [ ] Machine has NO prior state from this tap:
  ```sh
  brew list --cask 2>/dev/null | grep -Ei 'ruffle|bubble' && echo "DIRTY" || echo "clean"
  ls /Applications | grep -Ei 'ruffle|bubble' && echo "DIRTY" || echo "clean"
  brew untap arisweedler/flash 2>/dev/null; true
  ```
  If dirty, uninstall/zap leftovers first so this is a true fresh-install test.
- [ ] Note the arch (`uname -m`) — record it with results; we support arm64 and x86_64.
- [ ] Xcode CLT is NOT required for this test. Do not install it to make something pass;
  if a step demands a compiler, that is a design failure — record it.

## 1. Tap

- [ ] `brew tap arisweedler/flash`
  - Success: exits 0; `brew tap` lists `arisweedler/flash`.
  - Failure capture: full output; `brew tap-info arisweedler/flash`.

## 2. Install a game (the headline test)

- [ ] `brew install bubble-trouble`
  - Success, all of:
    - exits 0
    - installed the dependency chain automatically: ruffle cask + ari-flash-launcher
      formula, without being named on the command line:
      `brew list --cask` shows `ruffle` and `bubble-trouble`;
      `brew list --formula` shows `ari-flash-launcher`
    - `/Applications/Ruffle.app` exists
    - `/Applications/Bubble Trouble.app` exists
    - No password prompts beyond brew's normal behavior, no Xcode/CLT demands.
  - Failure capture: full install log (`brew install bubble-trouble 2>&1 | tee install.log`).

## 3. Launch path A — the .app (double-click UX)

- [ ] Open `/Applications/Bubble Trouble.app` from Finder by double-click (do NOT use
      `open` for the first launch — we are testing the real Gatekeeper path).
  - Success: game opens in a Ruffle window; dock shows the Bubble Trouble icon/name
    (not Ruffle's); NO Gatekeeper dialog ("can't be opened", "unidentified developer"),
    NO quarantine prompt.
  - [ ] Icon check: the app shows the game icon in Finder and the Dock (not a generic one).
  - [ ] Quit and relaunch once — still clean.
  - Failure capture: screenshot of any dialog; then run and record:
    ```sh
    codesign -dv --verbose=2 "/Applications/Bubble Trouble.app"
    spctl -a -vv "/Applications/Bubble Trouble.app"
    xattr -lr "/Applications/Bubble Trouble.app"
    ```

## 4. Launch path B — the CLI

- [ ] `which ari-flash-launcher` → a brew bin path.
- [ ] `ari-flash-launcher` (no args) → lists installed games, includes `bubble-trouble`.
- [ ] `ari-flash-launcher bubble-trouble` → game opens in Ruffle; terminal behavior
      matches the documented UX (record whether it blocks until quit).
- [ ] `ari-flash-launcher does-not-exist` → clear error, non-zero exit, lists what IS
      installed.
- Failure capture: `ari-flash-launcher --help` output; `RUFFLE_PATH= ari-flash-launcher -v bubble-trouble` if a verbose flag exists.

## 5. Ruffle standalone

- [ ] Open `/Applications/Ruffle.app` directly — launches clean (it is upstream's
      notarized build; any Gatekeeper dialog here means our cask broke quarantine
      handling or rehosting).

## 6. Save-data sanity (zap correctness groundwork)

- [ ] Play far enough to generate state (or just open/close the game), then record what
      actually got created:
  ```sh
  ls -la ~/Library/Application\ Support/ | grep -i ruffle
  find ~/Library/Application\ Support/rs.ruffle* -maxdepth 4 2>/dev/null
  ls ~/Library/Saved\ Application\ State/ | grep -Ei 'ruffle|arisweedler'
  ls ~/Library/Preferences/ | grep -Ei 'ruffle|arisweedler'
  ```
  Record the output — this validates (or corrects) the zap stanzas.

## 7. Upgrade path

Only when a second version/tag exists:
- [ ] `brew upgrade bubble-trouble` → rebuilds and replaces the app; relaunch works; no
      duplicate apps; `brew list --cask --versions bubble-trouble` shows the new version.

## 8. Uninstall + zap (must leave the machine spotless)

- [ ] `brew uninstall bubble-trouble`
  - `/Applications/Bubble Trouble.app` gone; Ruffle.app still present.
- [ ] `brew uninstall --zap bubble-trouble` is a no-op now (already uninstalled) — instead
      reinstall once (`brew install bubble-trouble`) and then:
      `brew uninstall --zap bubble-trouble`
  - App gone AND the game's zap paths (saved state, its SharedObjects dir) gone.
- [ ] `brew uninstall --zap ruffle`
  - `/Applications/Ruffle.app` gone; `~/Library/Application Support/rs.ruffle*` gone;
    ruffle prefs/caches/saved-state gone (per step 6 recordings).
- [ ] `brew autoremove` → removes `ari-flash-launcher` (it was only a dependency).
      If it does not, record it; README must document the extra
      `brew uninstall ari-flash-launcher`.
- [ ] Final sweep — expect NO hits:
  ```sh
  ls /Applications | grep -Ei 'ruffle|bubble'
  brew list | grep -Ei 'ruffle|bubble|ari-flash'
  find ~/Library -maxdepth 3 \( -iname '*ruffle*' -o -iname '*arisweedler*' \) 2>/dev/null
  ```
- [ ] `brew untap arisweedler/flash` → exits 0.

## 9. Report

Record for the run: date, macOS version, arch, brew version, and per-phase PASS/FAIL
with captured logs for failures. A release is acceptable only when phases 1–5 and 8
fully pass on a fresh machine.
