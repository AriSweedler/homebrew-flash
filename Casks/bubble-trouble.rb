# THE TEMPLATE for game casks in this tap.
#
# To add a new game, copy this file to Casks/<slug>.rb and change SIX things:
#   (1) the cask token below (must equal the filename and the games/<slug>
#       dir; also update the livecheck regex to match this token's tags)
#   (2) version
#   (3) sha256 (from scripts/cut-release output; "REPLACE_AT_RELEASE" until then)
#   (4) name (the display name; also the .app name the bundler produces —
#       update the `app "<Name>.app"` stanza and the Build comment above
#       preflight to match)
#   (5) desc (must stay in sync with the preflight --desc value — it appears
#       twice in every game cask)
#   (6) the preflight args: --name/--id/--swf/--icon, the one-line --desc,
#       --updated (YYYY-MM-DD of this release), --window (~2x the swf stage),
#       AND the zap path
# Then follow the ADD-A-GAME checklist in README.md to tag and cut the release.
cask "bubble-trouble" do # (1)
  version "1.1.0" # (2)
  sha256 "bb6259699473c382c0a70367a9dcabc2ad88e2f50a6de287f68e1b8fe5403a0b"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/flash-bundler, launcher/launcher, games/<slug>/{game.swf,icon.png}.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/bubble-trouble-v#{version}/bubble-trouble-#{version}.tar.gz"
  name "Bubble Trouble" # (4)
  desc "Pop bouncing bubbles with your harpoon before they bounce into you" # (5)
  homepage "https://github.com/AriSweedler/homebrew-flash"

  # All the tap's games share one GitHub repo, so the default GithubLatest
  # strategy would report whatever release happens to be marked 'latest'
  # (another game's, or tools-v*). Scan ALL releases and anchor the regex to
  # this cask's own tag prefix instead.
  livecheck do
    url :url
    strategy :github_releases
    regex(/^bubble-trouble-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on cask: "arisweedler/flash/ruffle"
  depends_on :macos

  # NOTE: file order is cosmetic (brew style enforces it); at install time the
  # preflight block always executes BEFORE the app artifact is moved.
  app "Bubble Trouble.app"

  # Build "<staged_path>/Bubble Trouble.app" from the staged swf + icon:
  # icns generation, Info.plist, prebuilt universal launcher, then
  # `xattr -cr` + ad-hoc codesign. The xattr step is load-bearing: Homebrew
  # quarantines staged files, and a quarantined Mach-O is SIGKILLed on exec.
  # Invoked via /bin/bash so lost exec bits or script quarantine can never
  # matter. The bundler is fail-fast; a failure here rolls back the install.
  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/flash-bundler",
                     "--name", "Bubble Trouble", # (6) this arg block + zap below
                     "--id", "com.arisweedler.flash.bubble-trouble",
                     "--swf", "#{staged_path}/games/bubble-trouble/game.swf",
                     "--icon", "#{staged_path}/games/bubble-trouble/icon.png",
                     "--desc", "Pop bouncing bubbles with your harpoon before they bounce into you",
                     "--updated", "2026-08-28",
                     "--window", "1400x900", # 2x the swf stage (700x450)
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  # Ruffle keys SharedObjects (save data) by the swf's on-disk location, and
  # the swf lives inside the installed app bundle — interpolate appdir so a
  # non-default --appdir install still zaps its saves.
  zap trash: "~/Library/Application Support/ruffle/SharedObjects/localhost#{appdir}/Bubble Trouble.app*"
end
