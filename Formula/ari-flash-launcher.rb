class AriFlashLauncher < Formula
  desc "CLI to launch brew-installed Flash games in Ruffle"
  homepage "https://github.com/AriSweedler/homebrew-flash"
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/tools-v1.0.0/ari-flash-tools-1.0.0.tar.gz"
  version "1.0.0"
  sha256 "41ca2ba0a54a2fe29ba9fe227a5eeb76dc0b3a06badd0d7e44f245f3adbbbc15"
  license "MIT"

  def install
    bin.install "bin/ari-flash-launcher"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/ari-flash-launcher --help")
  end
end
