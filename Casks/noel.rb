cask "noel" do
  version "1.1.0"
  sha256 "15e3293ce75f23def73a0c2a98a90493938d5f98f24bb56f42d1b34aaf67b431"

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
