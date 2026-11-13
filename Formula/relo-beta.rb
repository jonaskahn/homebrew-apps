class ReloBeta < Formula
  desc "Local proxy letting coding agents talk to any model"
  homepage "https://github.com/jonaskahn/relo"
  license "AGPL-3.0-only"

  on_macos do
    on_arm do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.11-beta.124.eaf47e89/relo-0.2.11-beta.124.eaf47e89-darwin-arm64.tar.gz"
      sha256 "a7a8e4923e83ebe25abbace777171ab2e0cdabd6aed4bd4ae70f6884a1c594d5"
    end
    on_intel do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.11-beta.124.eaf47e89/relo-0.2.11-beta.124.eaf47e89-darwin-amd64.tar.gz"
      sha256 "acf9538f0e10be8c052c5ce072615bcbe7de23338e8dca87639682fa70ffa905"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.11-beta.124.eaf47e89/relo-0.2.11-beta.124.eaf47e89-linux-arm64.tar.gz"
      sha256 "cee112ec4e7323e844322efb4e14a3c5f8d92205f22df45794dd17c799395f2a"
    end
    on_intel do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.11-beta.124.eaf47e89/relo-0.2.11-beta.124.eaf47e89-linux-amd64.tar.gz"
      sha256 "4b670eed1403f723de68739edc757f62ed6e6a776dab57ea8d95bb3ba63b0fd9"
    end
  end

  def install
    check_single_install!
    quiesce_daemon!
    bin.install "relo"
  end

  def caveats
    <<~EOS
      Relo keeps data in ~/.relo. Stop the daemon before removing Relo so
      the ports it serves are freed:
        relo daemon stop --force
      `brew uninstall relo` keeps your data, like apt and npm do. To remove
      the program and the data: `relo uninstall --wipe`, then
      `brew uninstall relo`. Do not use `brew services`; autostart is
      `relo autostart enable|disable`.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/relo version")
  end

  # Single-method rule: at most one Relo provides the relo command. A
  # Relo.app bundle, a Linux package, an npm global, or a manual copy
  # keeps updating through its own method, or is removed completely
  # first. Two installs would fight over the name, the home directory,
  # and the ports. This formula's own link, including the previous keg
  # during an upgrade, is never a conflict.
  def check_single_install!
    # Both sides are resolved before they are compared: macOS reaches
    # the same directory through /var and /private/var, so a raw
    # prefix compare would call the previous keg a stranger.
    cellar = realpath_of(HOMEBREW_CELLAR.to_s) + File::SEPARATOR
    own = realpath_of((HOMEBREW_PREFIX/"bin/relo").to_s)
    hits = []

    # Best effort: a node that cannot answer is not a reason to refuse.
    begin
      if (npm = which("npm"))
        npm_bin = Utils.safe_popen_read(npm, "prefix", "-g").strip
        shim = File.join(npm_bin, "bin", "relo")
        hits << shim if !npm_bin.empty? && File.executable?(shim)
      end
    rescue
      nil
    end
    hits << "/Applications/Relo.app" if File.exist?("/Applications/Relo.app")

    (ENV["PATH"] || "").split(File::PATH_SEPARATOR).each do |dir|
      next if dir.empty?

      candidate = File.join(dir, "relo")
      next unless File.executable?(candidate)

      next if File.directory?(candidate)

      resolved = realpath_of(candidate)
      next if resolved.start_with?(cellar) || resolved == own

      hits << candidate
    end

    return if hits.uniq.empty?

    odie <<~EOS
      another Relo install already provides the relo command:
      #{hits.uniq.map { |h| "  #{h}" }.join("\n")}
      Keep updating through that install, or remove it completely first:
        relo daemon stop --force && relo uninstall --keep-data
      then remove its program (delete Relo.app, npm uninstall -g @jonaskahn/relo,
      apt remove relo), and run brew install again.
    EOS
  end

  # Ends a daemon a previous Relo left running and frees the port its config.toml names, so an upgrade or reinstall
  # never hands the new binary a port the old one still holds. During an
  # upgrade the linked command is the previous keg, which is what
  # recognises the running daemon. Best effort: nothing to stop is fine.
  def quiesce_daemon!
    linked = (HOMEBREW_PREFIX/"bin/relo").to_s
    running = File.executable?(linked) ? linked : which("relo")
    return if running.nil? || running.to_s.empty?

    quiet_system running, "daemon", "stop", "--force"
  end

  # realpath_of resolves a path through every link, or returns it
  # unchanged when nothing is there to resolve.
  def realpath_of(path)
    File.realpath(path)
  rescue SystemCallError
    path
  end
end
