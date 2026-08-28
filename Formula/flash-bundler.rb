# The authoring CLI: swf + image -> icns + Info.plist + launcher -> signed .app.
# Game casks do NOT use this formula (they run their staged copy of the same
# script); install it to author NEW games or rebuild apps by hand.
class FlashBundler < Formula
  desc "Bundle a Flash swf + icon into a signed macOS app that runs in Ruffle"
  homepage "https://github.com/AriSweedler/homebrew-flash"
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/tools-v1.0.0/ari-flash-tools-1.0.0.tar.gz"
  sha256 "41ca2ba0a54a2fe29ba9fe227a5eeb76dc0b3a06badd0d7e44f245f3adbbbc15"

  def install
    # In the repo the script's default launcher is resolved relative to the
    # script's real path (../launcher/launcher). Homebrew symlinks bin/ but
    # the script realpath lands in this keg, where launcher/ is installed to
    # pkgshare — so retarget the marked DEFAULT_LAUNCHER line at pkgshare.
    inreplace "bin/flash-bundler",
              /^DEFAULT_LAUNCHER=.*$/,
              "DEFAULT_LAUNCHER=\"#{opt_pkgshare}/launcher/launcher\""
    bin.install "bin/flash-bundler"
    pkgshare.install "launcher"
  end

  test do
    assert_match "flash-bundler", shell_output("#{bin}/flash-bundler --help")
  end
end
