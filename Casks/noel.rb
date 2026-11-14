cask "noel" do
  version "1.0.0"
  sha256 "21893dad9378eb1262ffac0a82a6ff94f0c2fae786c48878b94e319a6a7e9d0e"

  url "https://github.com/Dmian0/noel/releases/download/v#{version}/Noel.zip"
  name "Noël"
  desc "Cozy Christmas menu bar player with 3D spinning holiday icons, snow, lights & hearth"
  homepage "https://github.com/Dmian0/noel"

  depends_on macos: ">= :ventura"

  app "Noel.app"

  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-cr", "#{appdir}/Noel.app"],
                   sudo: false
  end

  zap trash: [
    "~/Library/Preferences/com.damiatorres.noel.plist",
  ]
end
