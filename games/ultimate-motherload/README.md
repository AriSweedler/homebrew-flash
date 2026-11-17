# Ultimate Motherload on your Mac

Play **Ultimate Motherload**, jeremiah855's mod of the classic Flash game Motherload, as a normal
Mac app. It's free, and it takes a few minutes.

All the credit goes to the creator: **[jeremiah855/Ultimate_Motherload](https://github.com/jeremiah855/Ultimate_Motherload)**.
Go give the repo a star. I learned about this mod from
[this video](https://youtu.be/rZ_lx0kZVgU?is=1gy7N5u2Gnd-uO6j).

## Install

1. Open **Terminal** (press ⌘ Space, type `Terminal`, press Enter).
2. If you don't have Homebrew yet, install it: copy the one line from [brew.sh](https://brew.sh),
   paste it into Terminal, press Enter, and follow what it says.
3. Paste these three lines and press Enter:

   ```sh
   brew tap arisweedler/flash
   brew trust --tap arisweedler/flash
   brew install arisweedler/flash/ultimate-motherload
   ```

4. Open **Ultimate Motherload** from Launchpad or your Applications folder.

## What that command does

- Installs **[Ruffle](https://ruffle.rs)**, a free, open-source Flash player, and the game, in one go.
- Downloads the game straight from the creator's GitHub release and checks it's the exact file.
  This page hosts none of the game.
- Wraps it into a real Mac app with its own icon, so it opens like any other app.

## Remove it

```sh
brew uninstall --zap arisweedler/flash/ultimate-motherload
```
