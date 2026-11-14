cask "noel" do
  version "1.0.0"
  sha256 "acaf8e9df19804a3f6ac780d7c969b39c1645f1a0aa23edef75e08778d916ede"

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
