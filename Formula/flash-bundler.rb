# The authoring CLI: swf + image -> icns + Info.plist + launcher -> signed .app.
# Game casks do NOT use this formula (they run their staged copy of the same
# script); install it to author NEW games or rebuild apps by hand.
class FlashBundler < Formula
  desc "Bundle a Flash swf + icon into a signed macOS app that runs in Ruffle"
  homepage "https://github.com/AriSweedler/homebrew-flash"
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/tools-v1.3.0/ari-flash-tools-1.3.0.tar.gz"
  sha256 "3f4b238f19dfebc0725b409a948d7831e0a09a2ac9e548c98ec12f2932c2fe7b"

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
    # The inreplace above and the pkgshare launcher are the formula's whole
    # reason to exist — fail if the marked line stops matching or the
    # prebuilt launcher Mach-O stops shipping.
    launcher = (bin/"flash-bundler").read[/^DEFAULT_LAUNCHER="([^"]+)"/, 1]
    refute_nil launcher
    assert_path_exists Pathname(launcher)
  end
end
