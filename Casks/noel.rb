cask "noel" do
  version "1.0.1"
  sha256 "7c2fc5c45f6fb85c8f70595519b06a952a29fec264aec7462c4bcfd20680e513"

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
