# Homebrew Cask Formula for ZetaNotes
# This allows users to install without security warnings
# Submit to: https://github.com/Homebrew/homebrew-cask

cask "zetanotes" do
  version "1.0.0"
  sha256 :no_check  # Or calculate: shasum -a 256 ZetaNotes-v1.0.0.dmg

  url "https://github.com/rabah-khalek/zetanotes/releases/download/v#{version}/ZetaNotes-v#{version}.dmg"
  name "ZetaNotes"
  desc "Privacy-first note-taking with offline AI for Mac"
  homepage "https://github.com/rabah-khalek/zetanotes"

  livecheck do
    url :url
    strategy :github_latest
  end

  app "ZetaNotes.app"

  # Remove quarantine after installation (Homebrew does this automatically)
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/ZetaNotes.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Application Support/ZetaNotes",
    "~/Library/Caches/com.zetanotes.ZetaNotes",
    "~/Library/Preferences/com.zetanotes.ZetaNotes.plist",
    "~/Library/Saved Application State/com.zetanotes.ZetaNotes.savedState",
  ]
end
