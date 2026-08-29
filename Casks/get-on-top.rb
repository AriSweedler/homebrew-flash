# Copied from Casks/bubble-trouble.rb (the template); see its header comments.
cask "get-on-top" do # (1)
  version "1.0.0" # (2)
  sha256 "0000000000000000000000000000000000000000000000000000000000000000" # REPLACE_AT_RELEASE (3)

  # A FLAT tarball (no top-level dir) cut by scripts/cut-release from the tag:
  # bin/flash-bundler, launcher/launcher, games/<slug>/{game.swf,icon.png}.
  url "https://github.com/AriSweedler/homebrew-flash/releases/download/get-on-top-v#{version}/get-on-top-#{version}.tar.gz"
  name "Get On Top" # (4)
  desc "Classic Flash game, bundled at install into a signed app that runs in Ruffle"
  homepage "https://github.com/AriSweedler/homebrew-flash"

  depends_on cask: "arisweedler/flash/ruffle"
  depends_on :macos

  # NOTE: file order is cosmetic (brew style enforces it); at install time the
  # preflight block always executes BEFORE the app artifact is moved.
  app "Get On Top.app"

  # Build "<staged_path>/Get On Top.app" from the staged swf + icon:
  # icns generation, Info.plist, prebuilt universal launcher, then
  # `xattr -cr` + ad-hoc codesign. The xattr step is load-bearing: Homebrew
  # quarantines staged files, and a quarantined Mach-O is SIGKILLed on exec.
  # Invoked via /bin/bash so lost exec bits or script quarantine can never
  # matter. The bundler is fail-fast; a failure here rolls back the install.
  preflight do
    system_command "/bin/bash",
                   args:         [
                     "#{staged_path}/bin/flash-bundler",
                     "--name", "Get On Top", # (5) this arg block + zap below
                     "--id", "com.arisweedler.flash.get-on-top",
                     "--swf", "#{staged_path}/games/get-on-top/game.swf",
                     "--icon", "#{staged_path}/games/get-on-top/icon.png",
                     "--version", version.to_s,
                     "--out", staged_path.to_s
                   ],
                   print_stderr: true
  end

  # Ruffle keys SharedObjects (save data) by the swf's on-disk location, and
  # the swf lives inside the installed app bundle.
  zap trash: "~/Library/Application Support/ruffle/SharedObjects/localhost/Applications/Get On Top.app*"
end
