class DitOffloader < Formula
  desc "Verified camera and audio card offloads from the command-line"
  homepage "https://github.com/ez-cohn/dit-offloader"
  url "https://github.com/ez-cohn/dit-offloader/archive/0f29fde34cf398b5d6b0e9fdef7772ab2e7478c9.tar.gz"
  version "0.4.0"
  sha256 "d604b7b420300cc5476c01f43bd667db04b5a0fa3eff8860607875f8e1c26465"
  license "MIT"
  head "https://github.com/ez-cohn/dit-offloader.git", branch: "main"

  depends_on :macos
  depends_on "xxhash"

  def install
    # The helper that makes each check read the copy from the drive, not from memory.
    system ENV.cc, "-O2", "-o", "dit-offloader-evict", "src/dit-offloader-evict.c"
    bin.install "bin/dit-offloader", "dit-offloader-evict"
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
    (testpath/"cached.bin").write "x" * 100_000
    assert_match(/^[01]$/, shell_output("#{bin}/dit-offloader-evict #{testpath}/cached.bin").strip)

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
