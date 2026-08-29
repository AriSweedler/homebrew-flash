# Copied from Casks/bubble-trouble.rb (the template); see its header comments.
cask "get-on-top" do
  version "1.1.0"
  sha256 "d26c18100c59d0c61e8bcc26bdd17ba1e2a39c1a23315086a69767af966a0f94"

  url "https://github.com/AriSweedler/homebrew-flash/releases/download/get-on-top-v#{version}/get-on-top-#{version}.tar.gz"
  name "Get On Top"
  desc "Two-player physics duel: wrestle your rival's head into the ground"
  homepage "https://github.com/AriSweedler/homebrew-flash"

  livecheck do
    url :url
    strategy :github_releases
    regex(/^get-on-top-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on cask: "arisweedler/flash/ruffle"
  depends_on :macos

  app "Get On Top.app"

  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/flash-bundler",
                     "--name", "Get On Top",
                     "--id", "com.arisweedler.flash.get-on-top",
                     "--swf", "#{staged_path}/games/get-on-top/game.swf",
                     "--icon", "#{staged_path}/games/get-on-top/icon.png",
                     "--desc", "Two-player physics duel: wrestle your rival's head into the ground",
                     "--updated", "2026-08-28",
                     "--window", "1000x750", # 2x the swf stage (500x375)
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  zap trash: "~/Library/Application Support/ruffle/SharedObjects/localhost#{appdir}/Get On Top.app*"
end
