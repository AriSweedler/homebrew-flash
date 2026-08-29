# Slime Volleyball — the ORIGINAL One Slime (2007): 1-player-vs-CPU Slime
# Volleyball ending in the Inferno boss
# applet bytecode (Q. Pendragon), run unmodified on the tap's pinned
# Temurin 17 JRE (ari-flash-jre) via the applet-harness + java-launcher.
# The applet class name rides in the payload as game/applet.conf.
#
# THE slime-volleyball cask (the user picked the Java original). The broken
# JS port lives on as `wip-slime-volleyball` for investigation. Version starts
# at 2.0.0 because the slime-volleyball-v1.0.0 tag immutably holds the old
# JS asset.
#
# Provenance, controls, and the redistribution note live in
# games/slime-volleyball/PROVENANCE.md.
cask "slime-volleyball" do
  version "2.1.1"
  sha256 "ed81fe6a79dfb2e0f74d66ce8fb3d7f6874e1f3c05c8a6d3057a198b364dc603"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, java-launcher/java-launcher, games/slime-volleyball/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/slime-volleyball-v#{version}/slime-volleyball-#{version}.tar.gz"
  name "Slime Volleyball"
  desc "Original One Slime (2007): 1P-vs-CPU Slime Volleyball on a bundled-tap JRE"
  homepage "https://oneslime.net/"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^slime-volleyball-v(\d+(?:\.\d+)+)$/i)
  end

  # The JRE cask provides $(brew --prefix)/bin/ari-flash-java; the CLI
  # formula (ari-flash-launcher) arrives via depends_on below.
  depends_on cask: "arisweedler/flash/ari-flash-jre"
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
                     "--payload", "#{staged_path}/games/slime-volleyball/game",
                     "--payload-name", "game",
                     "--icon", "#{staged_path}/games/slime-volleyball/icon.png",
                     "--launcher-bin", "#{staged_path}/java-launcher/java-launcher",
                     # The original embed size: the applet's internal 400px
                     # height minus the 50px ground band the site clipped —
                     # matches the authentic look (see PROVENANCE.md).
                     "--window", "750x375", # One Slime's original embed size
                     "--desc", "Original One Slime (2007): 1P-vs-CPU Slime Volleyball on a bundled-tap JRE",
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
  zap trash: "~/Library/Saved Application State/com.arisweedler.flash.slime-volleyball.savedState"
end
