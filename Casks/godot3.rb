# Godot 3 runtime for the tap's Godot-remake games — the same role ruffle
# plays for swf games. Pinned to 3.6 (the final Godot 3 release; the game
# projects here are Godot 3 and will not run on Godot 4). Installs as
# "Godot 3.app" so a user's Godot 4 install is never touched.
cask "godot3" do
  version "3.6"
  sha256 "00cc8c8708756ad336d36bbfafd0cb6becd61e5b8e7d826309a3f4d5dda2c275"

  url "https://github.com/godotengine/godot/releases/download/#{version}-stable/Godot_v#{version}-stable_osx.universal.zip",
      verified: "github.com/godotengine/godot/"
  name "Godot 3 (Ari's distro)"
  desc "Pinned Godot 3 runtime used by the tap's Godot-remake games"
  homepage "https://godotengine.org/"

  depends_on formula: "arisweedler/flash/ari-flash-launcher"
  depends_on :macos

  app "Godot.app", target: "Godot 3.app"

  # Game launchers exec Godot's binary directly, and Homebrew quarantines
  # everything it stages; a quarantined Mach-O exec is SIGKILLed. The app is
  # notarized (Prehensile Tales B.V.), so stripping quarantine is safe — and
  # also removes the first-open dialog.
  postflight do
    system_command "/usr/bin/xattr",
                   args:         ["-dr", "com.apple.quarantine", "#{appdir}/Godot 3.app"],
                   print_stderr: true
  end

  zap trash: [
    "~/Library/Application Support/Godot",
    "~/Library/Caches/Godot",
    "~/Library/Saved Application State/org.godotengine.godot.savedState",
  ]
end
