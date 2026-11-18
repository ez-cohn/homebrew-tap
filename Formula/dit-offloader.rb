class DitOffloader < Formula
  desc "Verified camera and audio card offloads from the command-line"
  homepage "https://github.com/ez-cohn/dit-offloader"
  url "https://github.com/ez-cohn/dit-offloader/archive/refs/tags/v0.2.3.tar.gz"
  sha256 "189b880fc07f38e64d609dfe518fad4b2747da7c844165f4a45fcebae1e70dc9"
  license "MIT"
  head "https://github.com/ez-cohn/dit-offloader.git", branch: "main"

  depends_on :macos
  depends_on "xxhash"

  def install
    bin.install "bin/dit-offloader"
  end

  def caveats
    <<~EOS
      Create your settings file, then practise with fake cards:
        dit-offloader init
        dit-offloader rehearse

      To offload over SSH, turn on "Allow full disk access for remote users" in
      System Settings > General > Sharing > Remote Login.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/dit-offloader --version")

    # A real offload of a fake card to two folders, without touching any drive.
    ENV["DIT_OFFLOADER_CONFIG"] = testpath/"config"
    ENV["DIT_OFFLOADER_STATE"] = testpath/"state"
    ENV["DIT_OFFLOADER_VOLUMES"] = testpath/"vol"
    (testpath/"vol/CARD/DCIM/100").mkpath
    (testpath/"vol/CARD/DCIM/100/A001C001.MP4").write "clip"
    (testpath/"d1").mkpath
    (testpath/"d2").mkpath
    (testpath/"config").write <<~EOS
      DESTINATIONS=("#{testpath}/d1" "#{testpath}/d2")
      AUTO_EJECT="no"
      HASH_ALGO="xxh128"
    EOS
    system bin/"dit-offloader", "start", "Test", "--day", "2026-01-02"

    log = nil
    60.times do
      log = Dir[testpath/"state/CAMA-*.log"].first
      break if log && File.read(log).include?("RESULT:")

      sleep 1
    end
    refute_nil log
    assert_match "RESULT: PASS", File.read(log)
    copy = testpath/"d2/Test/Footage/2026-01-02/CAMA"
    assert_path_exists copy/"DCIM/100/A001C001.MP4"
    refute_empty Dir[copy/"dit-offloader_CAMA_*.xxh128"]
  end
end
