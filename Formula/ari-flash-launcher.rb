class AriFlashLauncher < Formula
  desc "CLI to launch brew-installed Flash games in Ruffle"
  homepage "https://github.com/AriSweedler/homebrew-flash"
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/tools-v1.1.0/ari-flash-tools-1.1.0.tar.gz"
  version "1.0.0"
  sha256 "5b608bb5740180bcb829ac4f9bff7b4e4937f58331f06963192bc3387f154ea0"
  license "MIT"

  depends_on "jq"

  def install
    bin.install "bin/ari-flash-launcher"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/ari-flash-launcher --help")
  end
end
