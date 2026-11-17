# Ultimate Motherload — jeremiah855's mod of Motherload (on Speedox12's Motherload_SRE): new
# drills, hulls and engines, a third boss phase, a zoomed-out view, cheats and speedrun paths.
# FETCH-AT-INSTALL like super-slime-soccer: the swf is a 92.7 MB release asset of the author's
# own repository with no license text, so this tap hosts NONE of it. The preflight_steps
# site-vendor step downloads it from that release ON THE INSTALLING MACHINE, pinned by sha256
# (a re-upload under the same name fails the install loudly), and flash-bundler builds the app
# around it as for every Flash game. Install needs network once; play is offline.
cask "ultimate-motherload" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # REPLACE_AT_RELEASE

  # A FLAT tarball cut by scripts/cut-release from the tag: bin/flash-bundler,
  # bin/site-vendor, launcher/launcher, games/ultimate-motherload/ (icon + PROVENANCE.md).
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/ultimate-motherload-v#{version}/ultimate-motherload-#{version}.tar.gz"
  name "Ultimate Motherload"
  desc "Motherload mod: dig for minerals on Mars with new gear, cheats and a harder boss"
  homepage "https://github.com/jeremiah855/Ultimate_Motherload"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^ultimate-motherload-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on cask: "arisweedler/flash/ruffle"
  depends_on :macos

  app "Ultimate Motherload.app"

  preflight_steps do
    # The swf from the author's v1.0 release onto THIS machine, pinned by sha256. Homebrew runs
    # install steps in a sandbox with no network unless a step asks.
    run "/bin/bash",
        args:           [
          "{{staged_path}}/bin/site-vendor",
          "--base-url", "https://github.com/jeremiah855/Ultimate_Motherload/releases/download/v1.0",
          "--out", "{{staged_path}}/games/ultimate-motherload",
          "--path", "Ultimate_Motherload.swf",
          "--sha256", "Ultimate_Motherload.swf=acc20979d29bbaae7157dc7d307785306f49b40c3a72e66a2ca5f6a9027db0fb",
          "--max-time", "900" # 92.7 MB
        ],
        print_stderr:   true,
        network_access: true
    run "/bin/bash",
        args:         [
          "{{staged_path}}/bin/flash-bundler",
          "--name", "Ultimate Motherload",
          "--id", "com.arisweedler.flash.ultimate-motherload",
          "--swf", "{{staged_path}}/games/ultimate-motherload/Ultimate_Motherload.swf",
          "--icon", "{{staged_path}}/games/ultimate-motherload/icon.png",
          "--desc", "Motherload mod: dig for minerals on Mars with new gear, cheats and a harder boss",
          "--updated", "2026-11-14",
          "--window", "1100x800", # 2x the swf stage (550x400)
          "--version", "{{version}}",
          "--out", "{{staged_path}}"
        ],
        print_stderr: true
  end

  zap trash: "~/Library/Application Support/ruffle/SharedObjects/localhost#{appdir}/Ultimate Motherload.app*"
end
