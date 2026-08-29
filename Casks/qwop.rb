# Copied from Casks/bubble-trouble.rb (the template); see its header comments.
cask "qwop" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # REPLACE_AT_RELEASE

  url "https://github.com/AriSweedler/homebrew-flash/releases/download/qwop-v#{version}/qwop-#{version}.tar.gz"
  name "QWOP"
  desc "Sprint 100 metres controlling the runner's thighs and calves with Q, W, O, P"
  homepage "https://github.com/AriSweedler/homebrew-flash"

  livecheck do
    url :url
    strategy :github_releases
    regex(/^qwop-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on cask: "arisweedler/flash/ruffle"
  depends_on :macos

  app "QWOP.app"

  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/flash-bundler",
                     "--name", "QWOP",
                     "--id", "com.arisweedler.flash.qwop",
                     "--swf", "#{staged_path}/games/qwop/game.swf",
                     "--icon", "#{staged_path}/games/qwop/icon.png",
                     "--desc", "Sprint 100 metres controlling the runner's thighs and calves with Q, W, O, P",
                     "--updated", "2026-08-28",
                     # 2x QWOP's canonical 640x400 stage — VERIFY against the
                     # swf header once games/qwop/game.swf lands.
                     "--window", "1280x800",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  zap trash: "~/Library/Application Support/ruffle/SharedObjects/localhost#{appdir}/QWOP.app*"
end
