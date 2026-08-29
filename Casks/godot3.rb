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

  # Without this, the default livecheck strategy returns the latest 4.x
  # release and brew livecheck would suggest an upgrade to Godot 4 — which
  # breaks every game project here. Anchor to 3.x-stable tags so a
  # hypothetical 3.6.x patch stays visible while 4.x stays invisible.
  livecheck do
    url :url
    strategy :github_releases
    regex(/^(3(?:\.\d+)+)-stable$/i)
  end

  # The runtime CLI (`ari-flash-launcher <game>`) ships with ari's godot3
  # distro, so it arrives transitively with every game install.
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

  # NOTE: "Application Support/Godot" holds editor config AND app_userdata
  # save data for EVERY Godot game in this tap (user:// is keyed by each
  # project's config/name). Zapping godot3 deletes all Godot game saves.
  zap trash: [
    "~/Library/Application Support/Godot",
    "~/Library/Caches/Godot",
    "~/Library/Saved Application State/org.godotengine.godot.savedState",
  ]
end
