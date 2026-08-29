# homebrew-flash

Ari's Homebrew tap for rescued classic games on macOS. Each game installs as a
real, signed `.app` — Flash games open in [Ruffle](https://ruffle.rs), and a
couple of non-Flash rescues ship with their own offline runtime — plus a CLI
to launch any installed game from the terminal.

## Quickstart

```sh
brew tap arisweedler/flash
brew trust --tap arisweedler/flash
brew install arisweedler/flash/bubble-trouble
```

The `brew trust` step is required: Homebrew refuses to load formulae and casks
from non-official taps until you trust them (stored in `~/.homebrew/trust.json`,
or `$XDG_CONFIG_HOME/homebrew/trust.json`).

That one install pulls everything: the game, Ari's distro of Ruffle, and the
`ari-flash-launcher` CLI. Then either:

- double-click `/Applications/Bubble Trouble.app`, or
- run `ari-flash-launcher bubble-trouble`

## How it works

A game cask downloads a pinned, flat tarball (the game's `.swf`, its icon, the
bundler script, and a prebuilt universal launcher; non-Flash games swap the
swf for a payload directory and flash-bundler for wrap-bundler — see below)
from this repo's GitHub releases. At install time, on your machine, the bundler turns that into
`<Game>.app`: it generates the `.icns` from the icon, writes the Info.plist,
drops in the launcher binary, strips Homebrew's quarantine attributes, and
ad-hoc code-signs the bundle. Homebrew then moves the finished app to
`/Applications`. Because the app is built locally and never quarantined,
Gatekeeper has nothing to complain about — no "unidentified developer"
dialogs, and no Xcode or compiler is needed. The launcher inside the app
`execv`s Ruffle's binary against the embedded swf, so the game keeps its own
name and icon in the Dock.

The `ruffle` cask here repackages upstream's notarized nightly build — no
compiling from source, no DMG to click through.

## Listing your games

`ari-flash-launcher` (installed with everything) knows two views:

```sh
ari-flash-launcher list             # installed games: version, last updated,
                                    # one-line description ('ls' and
                                    # 'list-installed' are the same)
ari-flash-launcher list-upstream    # everything the tap offers, straight from
                                    # GitHub (no brew involved); '*' marks the
                                    # ones you already have
```

The installed list is read from the apps themselves (the bundlers bake the
version, update date, and description into each Info.plist), so it works
offline and stays honest no matter how an app arrived or left.

## The two CLIs

- **`ari-flash-launcher`** (installed automatically with ruffle):
  `ari-flash-launcher` lists installed games; `ari-flash-launcher <slug>`
  launches one; `ari-flash-launcher path/to/file.swf` opens a raw swf in
  Ruffle.
- **`flash-bundler`** (`brew install arisweedler/flash/flash-bundler`,
  optional): the authoring tool. Point it at any swf + image and it produces
  a signed app:

  ```sh
  flash-bundler --name "My Game" --id com.arisweedler.flash.my-game \
                --swf game.swf --icon icon.png --version 1.0.0 --out ./build
  ```

## Adding a game

1. Drop the files into `games/<slug>/` as `game.swf` and `icon.png`
   (any sips-readable image works; 1024x1024 is ideal).
2. Copy `Casks/bubble-trouble.rb` (the commented template) to
   `Casks/<slug>.rb` and change the five marked fields.
3. Commit, then tag and cut the immutable release asset:

   ```sh
   git tag <slug>-v<version> && git push origin main <slug>-v<version>
   scripts/cut-release <slug>-v<version> bin/flash-bundler launcher/launcher games/<slug>
   ```

4. Paste the printed `sha256 "..."` line into the cask, commit, push.
5. Run the [TESTING.md](TESTING.md) checklist on the test machine.

Steps 1 and 3–4 are automated: with the cask staged (sha256 placeholder
`REPLACE_AT_RELEASE`) and `games/<slug>/icon.png` in place, run
`scripts/finish-game-release <slug> ~/Downloads/<game>.swf`. It stages the
swf, parses the swf stage size and rewrites the cask's `--window` line to 2x,
validation-builds the app locally, commits, tags `<slug>-v<version>`, cuts
the release, and pastes the sha256 back into the cask.

Note the checklist as written is Flash-only: non-Flash games pass a different
path list to cut-release — `bin/wrap-bundler <stub-dir>/<stub> games/<slug>`
per the url comment in each slime cask.

## Non-Flash games (wrap-bundler)

Not everything worth rescuing was Flash. The tap has a second, parallel
pattern for directory-payload games, built by `bin/wrap-bundler` (same
icns/plist/sign pipeline as flash-bundler, payload dir instead of a swf):

- **Java applets** — the ORIGINAL applet bytecode, run unmodified by
  `applet-harness/slime-harness.jar` (a minimal AppletStub/Frame host) on the
  pinned notarized Temurin 17 JRE from the `ari-flash-jre` cask, exec'd by
  `java-launcher` (the ruffle pattern; `-Xdock:` flags carry the game's dock
  identity). The applet class rides in the payload as `game/applet.conf`.
  Examples: `slime-soccer`, `slime-volleyball` — each payload dir carries a
  PROVENANCE.md with sources, sha256s, and the freeware-redistribution note.
- **Godot 3 projects** — run by `godot-launcher` via the pinned `godot3`
  runtime cask. First launch copies the project to Application Support and
  imports assets headlessly there; the signed app stays read-only.
  Example: `godot-slime-soccer` (hectorbennett, MIT) — the remake variant,
  kept installable until formally deprecated.
- **Web builds** — wrapped in `web-launcher` (an offline WKWebView window; no
  network at play time, CDN scripts vendored). Self-contained, no runtime
  cask. Example: `wip-slime-volleyball` (mmkal/slimejs, MIT) — BROKEN
  upstream (its published dist has an empty games registry); kept only for
  investigation.

## Uninstalling

Everything is removable, including saves:

```sh
brew uninstall arisweedler/flash/bubble-trouble        # removes the .app
brew uninstall --zap arisweedler/flash/bubble-trouble  # + that game's Ruffle save data
brew uninstall --zap arisweedler/flash/ruffle          # + Ruffle and ALL games' saves/config
brew uninstall --zap arisweedler/flash/slime-soccer        # java original
brew uninstall --zap arisweedler/flash/slime-volleyball    # java original
brew uninstall --zap arisweedler/flash/godot-slime-soccer  # + its project copy and Godot user data
brew uninstall --zap arisweedler/flash/wip-slime-volleyball # + its WebKit storage/caches
brew uninstall --zap arisweedler/flash/godot3              # + Godot 3 runtime and its dirs
brew uninstall --cask arisweedler/flash/ari-flash-jre      # the tap's pinned JRE
brew autoremove                                        # removes ari-flash-launcher once
                                                       # nothing depends on it
```

Zapping `ruffle` deletes `~/Library/Application Support/ruffle`, which holds
the save data (Flash SharedObjects) for every game — zap games first if you
only want to remove one.

Likewise, zapping `godot3` deletes `~/Library/Application Support/Godot` and
`~/Library/Caches/Godot` — Godot keys per-app `user://` data under that one
directory, so this removes save data for EVERY Godot app on the machine,
including projects from a personal Godot install. Zap the games first; skip
the godot3 zap if you use Godot yourself.

If homebrew-cask ever ships its own `ruffle` token, use the tap-qualified
names: `brew install arisweedler/flash/ruffle`, etc.

## Testing

No install testing happens on the dev machine. Acceptance is
[TESTING.md](TESTING.md) run top-to-bottom on a fresh test machine.

## Repo layout

```
Casks/            runtime casks (ruffle.rb, godot3.rb, ari-flash-jre.rb) + one cask
                  per game (bubble-trouble.rb is the commented template for Flash games)
Formula/          ari-flash-launcher.rb (runtime CLI), flash-bundler.rb (authoring CLI)
bin/              the three CLI scripts (ari-flash-launcher, flash-bundler,
                  wrap-bundler), as shipped in release assets
completions/      zsh + bash completions, installed by the ari-flash-launcher formula
launcher/         launcher.m + prebuilt universal binary embedded in every Flash game app
web-launcher/     WKWebView stub embedded in offline web-build games (wip-slime-volleyball)
godot-launcher/   stub that runs a Godot 3 project via the godot3 cask (godot-slime-soccer)
java-launcher/    stub that execs the ari-flash-jre JRE with -Xdock identity (java applet games)
applet-harness/   SlimeRunner.java + prebuilt slime-harness.jar (minimal AppletStub/Frame host)
games/<slug>/     game payload, hosted in-repo: game.swf + icon.png for Flash games;
                  a web/, project/, or game/ (jar/class + applet.conf) dir + icon.png
                  for wrapped games (java payloads add PROVENANCE.md)
scripts/          cut-release (release-asset helper), finish-game-release
                  (one command: staged swf -> tagged, released, sha-filled cask)
```
