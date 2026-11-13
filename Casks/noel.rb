cask "noel" do
  version "1.0.0"
  sha256 "e5deb5fff3b052f393a5346897333c1fd59bb3bee394d92f092e5085e6685059"

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
