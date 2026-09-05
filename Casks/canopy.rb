cask "canopy" do
  version "1.0"
  sha256 "3cd0aaf58496e792763d893f0a4b4c417582d6fcbb7fe0ed1484cf160b9cff3c"

  url "https://github.com/mrKangHo/Canopy/releases/download/v#{version}/Canopy.zip"
  name "Canopy"
  desc "Live nature-video wallpaper for macOS, powered by Pixabay"
  homepage "https://github.com/mrKangHo/Canopy"

  depends_on macos: ">= :ventura"

  app "Canopy.app"

  zap trash: [
    "~/Library/Caches/com.videowallpaper.app",
    "~/Library/Preferences/com.videowallpaper.app.plist",
  ]

  caveats <<~EOS
    Canopy is signed ad-hoc, not notarized by Apple. On first launch, macOS
    Gatekeeper will refuse to open it as "from an unidentified developer".
    Right-click (or Control-click) Canopy.app in /Applications and choose
    Open once to allow it — this is only needed the first time.
  EOS
end
