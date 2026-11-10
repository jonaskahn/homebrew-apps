class ReloBeta < Formula
  desc "Local proxy letting coding agents talk to any model"
  homepage "https://github.com/jonaskahn/relo"
  license "AGPL-3.0-only"

  on_macos do
    on_arm do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.9-beta.109.c3e26224/relo-0.2.9-beta.109.c3e26224-darwin-arm64.tar.gz"
      sha256 "09ac067247213eed7d6d13c7f91d24b101de236bfbda079a58f80f48fe665616"
    end
    on_intel do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.9-beta.109.c3e26224/relo-0.2.9-beta.109.c3e26224-darwin-amd64.tar.gz"
      sha256 "ab337c6bc7c5543675fc1dc5b9ce3a459d9d9a37e3b802d59bfa0c57419fa4fc"
    end
  end

  on_linux do
    on_arm do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.9-beta.109.c3e26224/relo-0.2.9-beta.109.c3e26224-linux-arm64.tar.gz"
      sha256 "9d62e6fe897faf15d42d8f6d3ab49be63e5514f1754789c3a72533264d8225ca"
    end
    on_intel do
      url "https://github.com/jonaskahn/relo/releases/download/v0.2.9-beta.109.c3e26224/relo-0.2.9-beta.109.c3e26224-linux-amd64.tar.gz"
      sha256 "76be051b222c75b0675e75bf51c557a2ba3885cc1db0de63f9b8d405e89b4437"
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
