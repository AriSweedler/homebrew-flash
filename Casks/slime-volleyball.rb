# Slime Volleyball — mmkal/slimejs (MIT), a faithful machine-translation of
# the original Java applet to canvas JS, vendored as a fully-offline build
# and wrapped in the tap's WKWebView stub (web-launcher). Self-contained:
# no runtime cask needed.
#
# TRIAL CANDIDATE: installed side-by-side with slime-soccer so one of the two
# slime approaches can be kept and the other deprecated after testing.
cask "slime-volleyball" do
  version "1.0.0"
  sha256 "9cb6b1e0b83f5c02d48ffa0b8c1320fe37e35c44854c87be7e7d60d90f5c145e"

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/wrap-bundler, web-launcher/web-launcher, games/slime-volleyball/.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/slime-volleyball-v#{version}/slime-volleyball-#{version}.tar.gz"
  name "Slime Volleyball"
  desc "Faithful JS port of the classic Java-applet Slime Volleyball (mmkal/slimejs)"
  homepage "https://github.com/mmkal/slimejs"

  # All the tap's games share one GitHub repo; scan all releases and anchor
  # to this cask's own tag prefix (see the template's livecheck comment).
  livecheck do
    url :url
    strategy :github_releases
    regex(/^slime-volleyball-v(\d+(?:\.\d+)+)$/i)
  end

  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Slime Volleyball.app"

  # Same build-at-install pattern as the flash games; wrap-bundler carries the
  # same quarantine-strip-then-sign invariant as flash-bundler.
  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/wrap-bundler",
                     "--name", "Slime Volleyball",
                     "--id", "com.arisweedler.flash.slime-volleyball",
                     "--payload", "#{staged_path}/games/slime-volleyball/web",
                     "--payload-name", "web",
                     "--icon", "#{staged_path}/games/slime-volleyball/icon.png",
                     "--launcher-bin", "#{staged_path}/web-launcher/web-launcher",
                     "--window", "1040x640", # canvas is 1000x500 plus chrome
                     "--desc", "Faithful JS port of the classic Java-applet Slime Volleyball (mmkal/slimejs)",
                     "--updated", "2026-08-28",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  # WKWebView's per-app storage (HTTPStorages glob also covers the
  # .binarycookies sibling file macOS creates for any CFNetwork/WebKit app).
  zap trash: [
    "~/Library/Caches/com.arisweedler.flash.slime-volleyball",
    "~/Library/HTTPStorages/com.arisweedler.flash.slime-volleyball*",
    "~/Library/Preferences/com.arisweedler.flash.slime-volleyball.plist",
    "~/Library/Saved Application State/com.arisweedler.flash.slime-volleyball.savedState",
    "~/Library/WebKit/com.arisweedler.flash.slime-volleyball",
  ]
end
