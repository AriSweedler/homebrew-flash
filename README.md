# homebrew-flash

Ari's Homebrew tap for classic Flash games on macOS. Each game installs as a
real, signed `.app` that opens in [Ruffle](https://ruffle.rs), plus a CLI to
launch any installed game from the terminal.

## Quickstart

```sh
brew tap arisweedler/flash
brew install bubble-trouble
```

That one install pulls everything: the game, Ari's distro of Ruffle, and the
`ari-flash-launcher` CLI. Then either:

- double-click `/Applications/Bubble Trouble.app`, or
- run `ari-flash-launcher bubble-trouble`

## How it works

A game cask downloads a pinned, flat tarball (the game's `.swf`, its icon, the
bundler script, and a prebuilt universal launcher) from this repo's GitHub
releases. At install time, on your machine, the bundler turns that into
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

## Uninstalling

Everything is removable, including saves:

```sh
brew uninstall bubble-trouble          # removes the .app
brew uninstall --zap bubble-trouble    # + that game's Ruffle save data
brew uninstall --zap ruffle            # + Ruffle and ALL games' saves/config
brew autoremove                        # removes ari-flash-launcher once
                                       # nothing depends on it
```

Zapping `ruffle` deletes `~/Library/Application Support/ruffle`, which holds
the save data (Flash SharedObjects) for every game — zap games first if you
only want to remove one.

If homebrew-cask ever ships its own `ruffle` token, use the tap-qualified
names: `brew install arisweedler/flash/ruffle`, etc.

## Testing

No install testing happens on the dev machine. Acceptance is
[TESTING.md](TESTING.md) run top-to-bottom on a fresh test machine.

## Repo layout

```
Casks/            ruffle.rb + one cask per game (bubble-trouble.rb is the template)
Formula/          ari-flash-launcher.rb (runtime CLI), flash-bundler.rb (authoring CLI)
bin/              the two CLI scripts, as shipped in release assets
launcher/         launcher.m + prebuilt universal binary embedded in every game app
games/<slug>/     game.swf + icon.png, hosted in-repo
scripts/          cut-release (release-asset helper)
```
