# Super Slime Soccer — a branded WKWebView wrapper around the LIVE
# superslimesoccer.io (Jens Dahl Møllerhøj's modern HTML5 successor to the
# classic slime games). The game is actively maintained with no offline build
# or license, so nothing of it is redistributed: the payload carries only a
# site.conf pointing web-launcher at the live site. Network required at play.
cask "super-slime-soccer" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # REPLACE_AT_RELEASE

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, web-launcher/web-launcher, games/super-slime-soccer/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/super-slime-soccer-v#{version}/super-slime-soccer-#{version}.tar.gz"
  name "Super Slime Soccer"
  desc "Wrapper app for the live superslimesoccer.io (network required)"
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
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Super Slime Soccer",
                     "--id", "com.arisweedler.flash.super-slime-soccer",
                     "--payload", "#{staged_path}/games/super-slime-soccer/web",
                     "--payload-name", "web",
                     "--icon", "#{staged_path}/games/super-slime-soccer/icon.png",
                     "--launcher-bin", "#{staged_path}/web-launcher/web-launcher",
                     "--window", "1280x800", # roomy default; the site is responsive
                     "--desc", "Wrapper app for the live superslimesoccer.io (network required)",
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
