# Slime Volleyball — One Slime (1-player-vs-CPU, ending in the Inferno boss)
# as the AUTHOR'S OFFICIAL JavaScript port served on oneslime.net, vendored
# offline into the tap's WKWebView stub (web-launcher). Chosen over the 2007
# applet bytecode: the JS port renders via requestAnimationFrame — display-
# synced 60 FPS versus the applet's 20ms/50fps thread loop.
#
# THE slime-volleyball cask. Earlier lives: v1.x the broken slimejs port
# (now wip-slime-volleyball), v2.0-2.1.x the 1999/2007 Java applets.
#
# Provenance, controls, and the redistribution note live in
# games/slime-volleyball/PROVENANCE.md.
cask "slime-volleyball" do
  version "2.2.0"
  sha256 "1bf0f6b7938826a4c13e33a4465157f01f4c9cdec167162c49820da8685a5bfd"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, web-launcher/web-launcher, games/slime-volleyball/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/slime-volleyball-v#{version}/slime-volleyball-#{version}.tar.gz"
  name "Slime Volleyball"
  desc "One Slime (1P-vs-CPU): the author's official 60 FPS JS port, offline"
  homepage "https://oneslime.net/"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^slime-volleyball-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Slime Volleyball.app"

  # Same build-at-install pattern as the flash games; wrap-bundler performs
  # the invariant chain: assemble -> xattr -cr -> ad-hoc sign -> verify.
  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Slime Volleyball",
                     "--id", "com.arisweedler.flash.slime-volleyball",
                     "--payload", "#{staged_path}/games/slime-volleyball/web",
                     "--payload-name", "web",
                     "--icon", "#{staged_path}/games/slime-volleyball/icon.png",
                     "--launcher-bin", "#{staged_path}/web-launcher/web-launcher",
                     # The original embed size: the applet's internal 400px
                     # height minus the 50px ground band the site clipped —
                     # matches the authentic look (see PROVENANCE.md).
                     "--window", "750x375", # exactly the canvas; wrapper page has zero margin
                     "--desc", "One Slime (1P-vs-CPU): the author's official 60 FPS JS port, offline",
                     "--updated", "2026-08-29",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  # WKWebView's per-app storage (the game itself uses no localStorage, but
  # WebKit still creates the dirs; HTTPStorages glob covers .binarycookies).
  zap trash: [
    "~/Library/Caches/com.arisweedler.flash.slime-volleyball",
    "~/Library/HTTPStorages/com.arisweedler.flash.slime-volleyball*",
    "~/Library/Preferences/com.arisweedler.flash.slime-volleyball.plist",
    "~/Library/Saved Application State/com.arisweedler.flash.slime-volleyball.savedState",
    "~/Library/WebKit/com.arisweedler.flash.slime-volleyball",
  ]
end
