class AriFlashLauncher < Formula
  desc "CLI to launch brew-installed Flash games in Ruffle"
  homepage "https://github.com/AriSweedler/homebrew-flash"
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/tools-v1.3.0/ari-flash-tools-1.3.0.tar.gz"
  # No version stanza: brew infers it from the asset filename. An explicit one
  # pinned at 1.0.0 masked upgrades for two releases — never reintroduce it.
  sha256 "3f4b238f19dfebc0725b409a948d7831e0a09a2ac9e548c98ec12f2932c2fe7b"
  license "MIT"

  depends_on "jq"

  def install
    bin.install "bin/ari-flash-launcher"
    zsh_completion.install "completions/_ari-flash-launcher"
    bash_completion.install "completions/ari-flash-launcher.bash" => "ari-flash-launcher"
  end

  test do
    assert_match "Usage:", shell_output("#{bin}/ari-flash-launcher --help")
  end
end
