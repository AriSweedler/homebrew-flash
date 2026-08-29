# TESTING.md — acceptance checklist for the test machine

All acceptance testing happens on a dedicated test machine, never on the dev machine.
Run every phase in order. Each step lists the command, what success looks like, and
what to capture if it fails. If any step fails: capture the output, stop, and bring
it back to the drawing board — do not hand-fix the test machine.

## 0. Preconditions

- [ ] Machine has Homebrew installed and working: `brew --version`
- [ ] Machine has NO prior state from this tap:
  ```sh
  brew list --cask 2>/dev/null | grep -Ei 'ruffle|godot|bubble|slime|qwop|get.on.top|ari-flash|temurin' && echo "DIRTY" || echo "clean"
  ls /Applications | grep -Ei 'ruffle|godot|bubble|slime|qwop|get.on.top' && echo "DIRTY" || echo "clean"
  ls "$(brew --prefix)/bin" 2>/dev/null | grep -Ei 'ari-flash' && echo "DIRTY" || echo "clean"
  brew untap arisweedler/flash 2>/dev/null; true
  ```
  If dirty, uninstall/zap leftovers first so this is a true fresh-install test.
  A hit on `godot` is expected if the test machine has a personal Godot
  install — judge those by path. Extend the pattern when a new game's display
  name shares no token with these.
- [ ] Note the arch (`uname -m`) — record it with results; we support arm64 and x86_64.
- [ ] Xcode CLT is NOT required for this test. Do not install it to make something pass;
  if a step demands a compiler, that is a design failure — record it.

## 1. Tap

- [ ] `brew tap arisweedler/flash`
  - Success: exits 0; `brew tap` lists `arisweedler/flash`.
  - Failure capture: full output; `brew tap-info arisweedler/flash`.
- [ ] `brew trust --tap arisweedler/flash`
  - Required: Homebrew refuses to load formulae/casks from untrusted
    non-official taps. Success: exits 0; `brew trust --json=v1` lists the tap.

## 2. Install a game (the headline test)

- [ ] `brew install arisweedler/flash/bubble-trouble`
  - Success, all of:
    - exits 0
    - installed the dependency chain automatically: ruffle cask + ari-flash-launcher
      formula, without being named on the command line:
      `brew list --cask` shows `ruffle` and `bubble-trouble`;
      `brew list --formula` shows `ari-flash-launcher`
    - `/Applications/Ruffle.app` exists
    - `/Applications/Bubble Trouble.app` exists
    - No password prompts beyond brew's normal behavior, no Xcode/CLT demands.
  - Failure capture: full install log (`brew install arisweedler/flash/bubble-trouble 2>&1 | tee install.log`).

## 2b. Install the wrapped games

- [ ] `brew install arisweedler/flash/slime-soccer` (the JAVA original)
  - Success: pulls the `ari-flash-jre` cask automatically;
    `$(brew --prefix)/bin/ari-flash-java` exists and `ari-flash-java -version`
    reports Temurin 17; `/Applications/Slime Soccer.app` exists.
- [ ] `brew install arisweedler/flash/slime-volleyball` (official JS port, offline)
  - Success: exits 0; NO JRE needed for this one; `/Applications/Slime Volleyball.app` exists.
- [ ] `brew install arisweedler/flash/slime-volleyball-2p` (the PvP original)
  - Success: exits 0 (JRE already present); `/Applications/Slime Volleyball 2P.app` exists.
- [ ] `brew install arisweedler/flash/godot-slime-soccer` (godot trial variant)
  - Success: pulls the `godot3` cask automatically; `/Applications/Godot 3.app`
    and `/Applications/Godot Slime Soccer.app` exist.
- [ ] `brew install arisweedler/flash/super-slime-soccer` (fetch-at-install)
  - Needs NETWORK during install (preflight downloads the game from
    superslimesoccer.io; the tap ships none of it). Success: exits 0;
    `/Applications/Super Slime Soccer.app` exists. With Wi-Fi off the install
    must FAIL LOUDLY naming the URL and the network hint.
- [ ] `brew install arisweedler/flash/wip-slime-volleyball` — EXPECTED BROKEN
      (blank canvas; upstream dist bug). Install must still succeed and the
      .app must open a window; record what it shows.

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

## 3b. Launch the wrapped games

Wrapped originals (deferred GUI checks from authoring — all four matter):
- [ ] Double-click `/Applications/Slime Soccer.app` — window renders at 700x350;
      dock shows the game name/icon (not a generic java cup); keyboard input
      works; focus returns after cmd-tab away and back.
- [ ] Double-click `/Applications/Slime Volleyball.app` — window at 750x375
      (One Slime, 1-player-vs-CPU, the author's official 60 FPS JS port):
      motion is display-synced smooth; arrows move/jump; click to start.
- [ ] Double-click `/Applications/Slime Volleyball 2P.app` — window at 700x350;
      both players' keys work on one keyboard (P1 A/W/D, P2 arrows).
- [ ] All three run with Wi-Fi off (all bytecode/JS-audited: no network).
- [ ] Quitting the window fully exits the process (no lingering java in
      `ps -ax | grep ari-flash-java`).
- [ ] Keyboard regression (fixed in soccer/volleyball 2.1.1, 2p 1.0.1): keys
      must work IMMEDIATELY after launch and again after clicking the window
      — the harness now forwards frame-level key events to the applet, so
      focus placement cannot swallow input.
- [ ] Smoothness (soccer/volleyball >= 2.1.2, 2p >= 1.0.2): rendering uses
      the JDK-default Metal pipeline, which is vsynced — the games are
      internally double-buffered and tick at ~50 FPS by design, so motion
      should be smooth and tear-free. (A briefly-shipped OpenGL default
      caused tearing/"flicker" and was reverted.) If stutter appears, A/B
      from a terminal and record which is smoother:
      ```sh
      "/Applications/Slime Volleyball.app/Contents/MacOS/SlimeVolleyball"          # Metal (default)
      ARI_FLASH_JAVA_OPTS="-Dsun.java2d.metal=false" \
        "/Applications/Slime Volleyball.app/Contents/MacOS/SlimeVolleyball"        # OpenGL
      ```
      ARI_FLASH_JAVA_OPTS takes arbitrary JVM flags.

Super Slime Soccer (offline HTML5):
- [ ] Turn Wi-Fi OFF, then double-click `/Applications/Super Slime Soccer.app`
      — the game must load and play fully offline (560x400 window). Arrows +
      Space = player 1; WASD + 1 = player 2. Accounts/leaderboards from the
      website do not exist in the app — expected.
- [ ] Unlock progress survives quit/relaunch (WKWebView localStorage).

Godot trial variant:
- [ ] Double-click `/Applications/Godot Slime Soccer.app`. Its FIRST
      launch must create
      `~/Library/Application Support/com.arisweedler.flash.godot-slime-soccer`
      (the writable project copy) and
      `~/Library/Application Support/Godot/app_userdata/Slime Soccer`,
      and the installed .app must stay unmodified — record that
      `find '/Applications/Godot Slime Soccer.app' -newer /Applications -type f`
      is empty.

## 4. Launch path B — the CLI

- [ ] `which ari-flash-launcher` → a brew bin path.
- [ ] `ari-flash-launcher` (no args) → lists installed games, includes `bubble-trouble`.
- [ ] `ari-flash-launcher bubble-trouble` → game opens in Ruffle; terminal behavior
      matches the documented UX (record whether it blocks until quit).
- [ ] `ari-flash-launcher does-not-exist` → clear error, non-zero exit, lists what IS
      installed.
- [ ] `ari-flash-launcher list` and `ari-flash-launcher ls` → same table as no-args;
      `ari-flash-launcher list-installed --porcelain` → tab-separated rows.
- [ ] `ari-flash-launcher list-upstream` → table of every released game with `*` next
      to installed ones (needs network; requires jq, which brew installed as a formula
      dependency).
- [ ] Completions installed: `ls $(brew --prefix)/share/zsh/site-functions/_ari-flash-launcher`
      and `$(brew --prefix)/etc/bash_completion.d/ari-flash-launcher` both exist; in a
      fresh zsh, `ari-flash-launcher <TAB>` offers the subcommands.
- Failure capture: `ari-flash-launcher --help` output;
  `ARI_FLASH_DRY_RUN=1 ari-flash-launcher bubble-trouble` (prints the `open` command it
  would run instead of running it). Separately: `RUFFLE_PATH` is the env var the in-app
  launcher honors to point at an alternate Ruffle binary — it is not read by
  `ari-flash-launcher` itself.

## 5. Ruffle standalone

- [ ] Open `/Applications/Ruffle.app` directly — launches clean (it is upstream's
      notarized build; any Gatekeeper dialog here means our cask broke quarantine
      handling or rehosting).

## 6. Save-data sanity (zap correctness groundwork)

- [ ] Play far enough to generate state (or just open/close the game), then record what
      actually got created:
  ```sh
  ls -la ~/Library/Application\ Support/ | grep -i ruffle
  find ~/Library/Application\ Support/ruffle -maxdepth 4 2>/dev/null
  ls ~/Library/Saved\ Application\ State/ | grep -Ei 'ruffle|arisweedler'
  ls ~/Library/Preferences/ | grep -Ei 'ruffle|arisweedler'
  ```
  Record the output — this validates (or corrects) the zap stanzas.

## 7. Upgrade path

Only when a second version/tag exists:
- [ ] `brew upgrade arisweedler/flash/bubble-trouble` → rebuilds and replaces the app;
      relaunch works; no duplicate apps;
      `brew list --cask --versions bubble-trouble` shows the new version.

## 7b. Re-testing after a fix (the iterate loop)

When the dev machine pushes a fix to the tap, pick up the changes on the test
machine with:

```sh
brew update                                        # git-pulls the tap clone
brew reinstall arisweedler/flash/bubble-trouble    # cask/script changed, same version
brew upgrade   arisweedler/flash/bubble-trouble    # version was bumped
```

- `brew update` is what refreshes third-party taps (they are plain git clones
  under `$(brew --prefix)/Library/Taps/arisweedler/homebrew-flash`); nothing
  reloads automatically without it.
- Release assets are IMMUTABLE by policy: a fix to anything inside a tarball
  (bundler, launcher, swf, icon) means a NEW tag + version bump + cut-release,
  never re-uploading a changed asset to the same tag (the pinned sha256 would
  mismatch). Cask-only or formula-only fixes (zap paths, plist of the cask,
  README) need no new asset — just push, `brew update`, `brew reinstall`.
- If you `brew untap` during cleanup, the trust entry is invalidated — re-run
  `brew trust --tap arisweedler/flash` after re-tapping.

## 8. Uninstall + zap (must leave the machine spotless)

- [ ] `brew uninstall arisweedler/flash/bubble-trouble`
  - `/Applications/Bubble Trouble.app` gone; Ruffle.app still present.
- [ ] `brew uninstall --zap arisweedler/flash/bubble-trouble` is a no-op now (already uninstalled) — instead
      reinstall once (`brew install arisweedler/flash/bubble-trouble`) and then:
      `brew uninstall --zap arisweedler/flash/bubble-trouble`
  - App gone AND the game's zap paths (saved state, its SharedObjects dir) gone.
- [ ] `brew uninstall --zap arisweedler/flash/ruffle`
  - `/Applications/Ruffle.app` gone; `~/Library/Application Support/ruffle` gone (dirs-crate path);
    ruffle prefs/caches/saved-state gone (per step 6 recordings).
- [ ] `brew uninstall --zap arisweedler/flash/slime-volleyball` → app gone AND its zap
      paths (from the cask file: WebKit storage/caches, saved state) gone.
- [ ] `brew uninstall --zap arisweedler/flash/slime-soccer` → app gone AND its zap paths
      (from the cask file: the Application Support project copy, Godot app_userdata) gone.
- [ ] `brew uninstall --zap arisweedler/flash/godot3` → `/Applications/Godot 3.app` gone
      AND its zap paths (from the cask file) gone.
- [ ] `brew autoremove` → removes `ari-flash-launcher` (it was only a dependency).
      If it does not, record it; README must document the extra
      `brew uninstall ari-flash-launcher`.
- [ ] Final sweep — expect NO hits:
  ```sh
  ls /Applications | grep -Ei 'ruffle|godot|bubble|slime|qwop|get.on.top'
  brew list | grep -Ei 'ruffle|godot|bubble|slime|qwop|get.on.top|ari-flash|temurin'
  find ~/Library -maxdepth 3 \( -iname '*ruffle*' -o -iname '*godot*' -o -iname '*slime*' -o -iname '*arisweedler*' \) 2>/dev/null
  ```
  A hit on `godot` is expected if the test machine has a personal Godot
  install — judge those by path. Extend the pattern when a new game's display
  name shares no token with these.
- [ ] `brew untap arisweedler/flash` → exits 0.

## 9. Report

Record for the run: date, macOS version, arch, brew version, and per-phase PASS/FAIL
with captured logs for failures. A release is acceptable only when phases 1–5 and 8
fully pass on a fresh machine.
