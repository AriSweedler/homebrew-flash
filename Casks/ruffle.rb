# Ari's distro of Ruffle: upstream's prebuilt, notarized nightly, installed
# without compiling from source (homebrew-core has no ruffle) and without
# clicking through a DMG. Every game cask in this tap depends on this cask.
cask "ruffle" do
  version "2026-08-28"
  sha256 "55d83d25d3bcc10552be06350301cb8d3e76851c21f79f91f71e20526e7e9f55"

  url "https://github.com/ruffle-rs/ruffle/releases/download/nightly-#{version}/ruffle-nightly-#{version.tr("-", "_")}-macos-universal.tar.gz",
      verified: "github.com/ruffle-rs/ruffle/"
  name "Ruffle (Ari's distro)"
  desc "Flash Player emulator, repackaged from upstream's notarized nightly build"
  homepage "https://ruffle.rs/"

  livecheck do
    url "https://github.com/ruffle-rs/ruffle"
    strategy :github_latest
    regex(/^nightly-(\d{4}-\d{2}-\d{2})$/i)
  end

  # The runtime CLI (`ari-flash-launcher <game>`) ships with ari's ruffle
  # distro, so it arrives transitively with every game install.
  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Ruffle.app"

  # Game launchers execv this app's binary directly. Homebrew propagates
  # com.apple.quarantine onto everything it stages, and exec of a quarantined
  # Mach-O is SIGKILLed on some macOS configurations. Ruffle.app is Developer
  # ID signed and notarized (Ruffle LLC), so stripping quarantine is safe; it
  # also removes the first-open confirmation dialog.
  postflight do
    system_command "/usr/bin/xattr",
                   args:         ["-dr", "com.apple.quarantine", "#{appdir}/Ruffle.app"],
                   print_stderr: false
  end

  # NOTE: "Application Support/ruffle" holds config AND the SharedObjects
  # save data for EVERY game in this tap (ruffle uses the dirs crate, not its
  # bundle id). Zapping ruffle deletes all flash game saves.
  zap trash: [
    "~/Library/Application Support/ruffle",
    "~/Library/Caches/ruffle",
    "~/Library/HTTPStorages/rs.ruffle.ruffle*",
    "~/Library/Preferences/rs.ruffle.ruffle.plist",
    "~/Library/Saved Application State/rs.ruffle.ruffle.savedState",
  ]
end
