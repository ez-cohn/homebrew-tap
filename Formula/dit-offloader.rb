class DitOffloader < Formula
  desc "Verified camera and audio card offloads from the command-line"
  homepage "https://github.com/ez-cohn/dit-offloader"
  url "https://github.com/ez-cohn/dit-offloader/archive/4b11108c9db61f7e5a78ffaf1c2ebb8524c6f116.tar.gz"
  version "0.1.0"
  sha256 "46e1e5a82823c322007628c6004da7fcbb0ae7db68d5d06db5f9adb509fc4cbe"
  license "MIT"

  depends_on :macos

  def install
    bin.install "bin/dit-offloader"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dit-offloader --version")
  end
end
