# Ari's Java runtime for classic-applet games: Eclipse Temurin 17 JRE,
# upstream's prebuilt per-arch tarball (Developer ID signed + notarized by
# Eclipse Foundation, JCDTMS22B4), installed without a .pkg and without sudo.
#
# Why 17 and not newer: java.applet.Applet survives through JDK 25 (removed
# in 26 by JEP 504), but Thread.stop() throws UnsupportedOperationException
# from JDK 20 on — and both slime games call Thread.stop() to end a match.
# 17 is the newest LTS where they run.
#
# This is a cask, not a formula, because Homebrew misparses the Temurin asset
# name ("...hotspot_17.0.20.1_1.tar.gz" infers version 1.1) and Formula/*.rb
# in this tap never carries an explicit version stanza; casks version
# explicitly by design. Rehosting via scripts/cut-release is impossible: it
# git-archives tracked files only, and a JRE will not be committed.
cask "ari-flash-jre" do
  arch arm: "aarch64", intel: "x64"

  version "17.0.20.1,1"
  sha256 arm:   "190480874ccceb358cbc840393207f77ac3e63a4c5f8129d0e23e9518b96ad05",
         intel: "333cb81123c36568586646c73c8fa2326dab8badc43f5ea388a90fff59c9df27"

  url "https://github.com/adoptium/temurin17-binaries/releases/download/jdk-#{version.csv.first}%2B#{version.csv.second}/OpenJDK17U-jre_#{arch}_mac_hotspot_#{version.csv.first}_#{version.csv.second}.tar.gz",
      verified: "github.com/adoptium/temurin17-binaries/"
  name "Ari's Flash-tap JRE (Temurin 17)"
  desc "Java 17 runtime for the tap's classic-applet games, from Temurin's signed build"
  homepage "https://adoptium.net/"

  livecheck do
    url "https://github.com/adoptium/temurin17-binaries"
    regex(/^jdk-(17(?:\.\d+)*)\+(\d+)$/i)
    strategy :github_latest do |json, regex|
      match = json["tag_name"]&.match(regex)
      next if match.blank?

      "#{match[1]},#{match[2]}"
    end
  end

  depends_on :macos

  # Stable, version-independent probe path for game launchers:
  #   $(brew --prefix)/bin/ari-flash-java
  # Deliberately NOT named "java" so it never shadows a real JDK on PATH.
  # The JVM resolves its home from the symlink's real path, so -Xdock:name=
  # / -Xdock:icon= and the bundled lib/ all work through it.
  binary "jdk-#{version.csv.first}+#{version.csv.second}-jre/Contents/Home/bin/java",
         target: "ari-flash-java"

  # Game launchers exec this JRE's binaries directly. Homebrew quarantines
  # cask downloads, and exec of a quarantined Mach-O is SIGKILLed. The JRE is
  # Developer ID signed and notarized (Eclipse Foundation), so stripping
  # quarantine is safe; it also removes the first-open confirmation dialog.
  postflight do
    system_command "/usr/bin/xattr",
                   args:         ["-dr", "com.apple.quarantine", staged_path.to_s],
                   print_stderr: false
  end

  caveats do
    <<~EOS
      Game launchers should exec:
        #{HOMEBREW_PREFIX}/bin/ari-flash-java
    EOS
  end
end
