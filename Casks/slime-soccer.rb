# Slime Soccer — hectorbennett/slime-soccer (MIT), a from-scratch Godot 3
# remake of the classic Java applet, vendored at a pinned commit and run via
# the tap's godot3 runtime cask (the ruffle pattern). On first launch the
# godot-launcher stub copies the project to Application Support and imports
# its assets headlessly there — the signed .app stays read-only.
#
# TRIAL CANDIDATE: installed side-by-side with slime-volleyball so one of the
# two slime approaches can be kept and the other deprecated after testing.
#
# Vendored from commit d9977cee1de6e6fe4d93be80b7145123b6c8a35c.
cask "slime-soccer" do
  version "1.0.0"
  sha256 "265de6a9a63b3b1a63bbbf4da4dd79e0677f7845e6d06f1973b241e980d5451b"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, godot-launcher/godot-launcher, games/slime-soccer/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/slime-soccer-v#{version}/slime-soccer-#{version}.tar.gz"
  name "Slime Soccer"
  desc "MIT remake of the classic Java-applet Slime Soccer (hectorbennett, Godot)"
  homepage "https://github.com/hectorbennett/slime-soccer"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^slime-soccer-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on cask: "arisweedler/flash/godot3"
  depends_on :macos

  app "Slime Soccer.app"

  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Slime Soccer",
                     "--id", "com.arisweedler.flash.slime-soccer",
                     "--payload", "#{staged_path}/games/slime-soccer/project",
                     "--payload-name", "project",
                     "--icon", "#{staged_path}/games/slime-soccer/icon.png",
                     "--launcher-bin", "#{staged_path}/godot-launcher/godot-launcher",
                     "--desc", "MIT remake of the classic Java-applet Slime Soccer (hectorbennett, Godot)",
                     "--updated", "2026-08-28",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  zap trash: [
    # The launcher's writable project copy (per-version) and Godot's per-game
    # user:// data (keyed by the project's config/name). Known limitation:
    # the launcher stages one copy per app version under
    # "~/Library/Application Support/com.arisweedler.flash.slime-soccer/<version>/",
    # and old version dirs persist across upgrades until this zap runs (or
    # until the launcher-side prune fix ships in a future release).
    "~/Library/Application Support/com.arisweedler.flash.slime-soccer",
    "~/Library/Application Support/Godot/app_userdata/Slime Soccer",
    "~/Library/Saved Application State/com.arisweedler.flash.slime-soccer.savedState",
  ]
end
