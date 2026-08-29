# Super Slime Soccer — Jens Dahl Møllerhøj's modern HTML5 successor to the
# classic slime games (superslimesoccer.io), FULLY OFFLINE after install.
# The game is actively maintained with no offline build or license, so this
# tap redistributes NOTHING of it: the preflight's site-vendor step downloads
# the game's files (a GameMaker HTML5 export: SSS.js + two texture pages)
# from the official site ON THE INSTALLING MACHINE — install needs network
# once — and wrap-bundler embeds them. web-launcher serves the payload
# through its in-app URL-scheme server (serve.conf): GameMaker XHRs its ini,
# which file:// forbids. Online-only site features (accounts, leaderboards)
# do not exist inside the offline app; local 1P/2P play is intact.
cask "super-slime-soccer" do
  version "1.1.0"
  sha256 "472d2cf40771188d4cc9d13995eb233f1242e2749e430271f56fdf4d6dce8a0d"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, bin/site-vendor, web-launcher/web-launcher,
  # games/super-slime-soccer/ (our index.html + serve.conf + icon only).
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/super-slime-soccer-v#{version}/super-slime-soccer-#{version}.tar.gz"
  name "Super Slime Soccer"
  desc "Modern HTML5 slime soccer, fetched at install and playable offline"
  homepage "https://www.superslimesoccer.io/"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^super-slime-soccer-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Super Slime Soccer.app"

  # Same build-at-install pattern as the flash games; wrap-bundler carries the
  # same quarantine-strip-then-sign invariant as flash-bundler.
  preflight do
    # Fetch the game from its official site onto THIS machine (the tap ships
    # none of it). Fails loudly offline: installing needs network once.
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/site-vendor",
                     "--base-url", "https://www.superslimesoccer.io",
                     "--out", "#{staged_path}/games/super-slime-soccer/web",
                     "--path", "html5game/SSS.js",
                     "--path", "html5game/SSS_texture_0.png",
                     "--path", "html5game/SSS_texture_1.png",
                     "--optional", "html5game/data.ini"
                   ],
                   print_stderr: true
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Super Slime Soccer",
                     "--id", "com.arisweedler.flash.super-slime-soccer",
                     "--payload", "#{staged_path}/games/super-slime-soccer/web",
                     "--payload-name", "web",
                     "--icon", "#{staged_path}/games/super-slime-soccer/icon.png",
                     "--launcher-bin", "#{staged_path}/web-launcher/web-launcher",
                     "--window", "560x400", # the GameMaker canvas's native size
                     "--desc", "Super Slime Soccer (superslimesoccer.io), offline after install",
                     "--updated", "2026-08-29",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  # WKWebView's per-app storage: localStorage here holds the game's unlocks/
  # progress, so zapping deletes save data.
  zap trash: [
    "~/Library/Caches/com.arisweedler.flash.super-slime-soccer",
    "~/Library/HTTPStorages/com.arisweedler.flash.super-slime-soccer*",
    "~/Library/Preferences/com.arisweedler.flash.super-slime-soccer.plist",
    "~/Library/Saved Application State/com.arisweedler.flash.super-slime-soccer.savedState",
    "~/Library/WebKit/com.arisweedler.flash.super-slime-soccer",
  ]
end
