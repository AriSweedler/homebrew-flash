# Slime Soccer — the ORIGINAL World Cup Soccer Slime applet bytecode
# (Q. Pendragon, 2002/2007), run unmodified on the tap's pinned Temurin 17
# JRE (ari-flash-jre) via the applet-harness + java-launcher. The applet
# class name rides in the payload as game/applet.conf, not Info.plist.
#
# THE slime-soccer cask (the user picked the Java original). The Godot remake
# lives on as `godot-slime-soccer` until formally deprecated. Version starts
# at 2.0.0 because the slime-soccer-v1.0.0 tag immutably holds the old godot
# asset.
#
# Provenance, controls, and the redistribution note live in
# games/slime-soccer/PROVENANCE.md.
cask "slime-soccer" do
  version "2.1.2"
  sha256 "4739c5d20c0324c08f2597a6059c90edf703e1929719f0ef13e0d8b3e6612c09"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, java-launcher/java-launcher, games/slime-soccer/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/slime-soccer-v#{version}/slime-soccer-#{version}.tar.gz"
  name "Slime Soccer"
  desc "Original 2002 World Cup Soccer Slime Java applet, run on a bundled-tap JRE"
  homepage "https://oneslime.net/"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^slime-soccer-v(\d+(?:\.\d+)+)$/i)
  end

  # The JRE cask provides $(brew --prefix)/bin/ari-flash-java; the CLI
  # formula (ari-flash-launcher) arrives via depends_on below.
  depends_on cask: "arisweedler/flash/ari-flash-jre"
  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Slime Soccer.app"

  # Same build-at-install pattern as the flash games; wrap-bundler performs
  # the invariant chain: assemble -> xattr -cr -> ad-hoc sign -> verify.
  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Slime Soccer",
                     "--id", "com.arisweedler.flash.slime-soccer",
                     "--payload", "#{staged_path}/games/slime-soccer/game",
                     "--payload-name", "game",
                     "--icon", "#{staged_path}/games/slime-soccer/icon.png",
                     "--launcher-bin", "#{staged_path}/java-launcher/java-launcher",
                     "--window", "700x350", # the original embed size
                     "--desc", "Original 2002 World Cup Soccer Slime Java applet, run on a bundled-tap JRE",
                     "--updated", "2026-08-29",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  # The game itself writes no files (bytecode-audited: no I/O, no network).
  # The running java process is bundle-less, so its prefs/saved state live
  # under the SHARED net.java.openjdk.java domains used by any Java app —
  # deliberately not zapped per game.
  zap trash: "~/Library/Saved Application State/com.arisweedler.flash.slime-soccer.savedState"
end
