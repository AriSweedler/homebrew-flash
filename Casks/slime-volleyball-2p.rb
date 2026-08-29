# Slime Volleyball 2P — the ORIGINAL two-player (PvP) Slime Volleyball
# applet bytecode (Q. Pendragon), run unmodified on the tap's pinned
# Temurin 17 JRE (ari-flash-jre) via the applet-harness + java-launcher.
# The applet class name rides in the payload as game/applet.conf.
#
# The PvP sibling of `slime-volleyball` (which is One Slime, 1P-vs-CPU).
# Fresh slug, so versioning starts at 1.0.0.
#
# Provenance, controls, and the redistribution note live in
# games/slime-volleyball-2p/PROVENANCE.md.
cask "slime-volleyball-2p" do
  version "1.0.2"
  sha256 "3b9b002818571e9d18b5b51a8d0dd95077b0f4eee531597340aef13b4cb021dc"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, java-launcher/java-launcher, games/slime-volleyball-2p/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/slime-volleyball-2p-v#{version}/slime-volleyball-2p-#{version}.tar.gz"
  name "Slime Volleyball 2P"
  desc "Original two-player (PvP) Slime Volleyball applet on a bundled-tap JRE"
  homepage "https://oneslime.net/"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^slime-volleyball-2p-v(\d+(?:\.\d+)+)$/i)
  end

  # The JRE cask provides $(brew --prefix)/bin/ari-flash-java; the CLI
  # formula (ari-flash-launcher) arrives via depends_on below.
  depends_on cask: "arisweedler/flash/ari-flash-jre"
  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Slime Volleyball 2P.app"

  # Same build-at-install pattern as the flash games; wrap-bundler performs
  # the invariant chain: assemble -> xattr -cr -> ad-hoc sign -> verify.
  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Slime Volleyball 2P",
                     "--id", "com.arisweedler.flash.slime-volleyball-2p",
                     "--payload", "#{staged_path}/games/slime-volleyball-2p/game",
                     "--payload-name", "game",
                     "--icon", "#{staged_path}/games/slime-volleyball-2p/icon.png",
                     "--launcher-bin", "#{staged_path}/java-launcher/java-launcher",
                     # The original embed size: the applet's internal 400px
                     # height minus the 50px ground band the site clipped —
                     # matches the authentic look (see PROVENANCE.md).
                     "--window", "700x350", # the original embed size
                     "--desc", "Original two-player (PvP) Slime Volleyball applet on a bundled-tap JRE",
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
  zap trash: "~/Library/Saved Application State/com.arisweedler.flash.slime-volleyball-2p.savedState"
end
