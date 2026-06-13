class ContainerCompose < Formula
  desc "Apple Container CLI compose plugin"
  homepage "https://github.com/Simplifi-ED/compose"
  url "https://github.com/Simplifi-ED/compose/releases/download/v0.0.1-rc2/compose-plugin.tar.gz"
  # Replaced automatically by the release workflow on each tag.
  sha256 "54197df7e9316a318c06c385e607244a86e1a3ce7f35e08f9b346a89889fbd76"
  license "Apache-2.0"

  depends_on macos: :sequoia
  depends_on arch: :arm64

  def install
    libexec.install "config.toml"
    (libexec/"bin").install "bin/compose"
  end

  def post_install
    link_plugin(
      dest: Pathname("/usr/local/libexec/container-plugins/compose"),
      source: opt_libexec
    )
  rescue StandardError => e
    ohai "Could not auto-link compose plugin: #{e.message}"
    manual_symlink_caveats
  end

  def caveats
    <<~EOS
      Install with: brew install simplifi-ed/compose/container-compose
      (Homebrew core ships a different formula also named container-compose.)

      If plugin discovery did not succeed automatically, create a symlink manually.
      Remove any existing plugin directory first — ln -sf into a directory nests
      the symlink and leaves a stale plugin loaded:

      Cask or PKG install (container under /usr/local):
        sudo rm -rf /usr/local/libexec/container-plugins/compose
        sudo mkdir -p /usr/local/libexec/container-plugins
        sudo ln -sf #{opt_libexec} /usr/local/libexec/container-plugins/compose

      Homebrew formula install (experimental brew install container):
        rm -rf #{HOMEBREW_PREFIX}/opt/container/libexec/container-plugins/compose
        mkdir -p #{HOMEBREW_PREFIX}/opt/container/libexec/container-plugins
        ln -sf #{opt_libexec} #{HOMEBREW_PREFIX}/opt/container/libexec/container-plugins/compose

      Verify discovery with:
        container system start
        container compose --help
    EOS
  end

  test do
    assert_match "compose", shell_output("#{opt_libexec}/bin/compose --help")
  end

  private

  def link_plugin(dest:, source:)
    dest.parent.mkpath
    return if dest.symlink? && dest.readlink == source

    if dest.exist? && !dest.symlink?
      raise "destination exists and is not a symlink: #{dest}"
    end

    if dest.parent.writable?
      dest.make_symlink(source)
      return
    end

    brew_dest = HOMEBREW_PREFIX/"opt/container/libexec/container-plugins/compose"
    brew_dest.parent.mkpath
    if brew_dest.parent.writable?
      brew_dest.make_symlink(source)
      return
    end

    raise "no writable plugin directory; run the manual symlink command from brew info container-compose"
  end

  def manual_symlink_caveats
    opoo <<~EOS
      Automatic plugin linking failed (likely a root-owned /usr/local install).
      Run the manual symlink commands shown in `brew info simplifi-ed/compose/container-compose`
      with sudo. Remove /usr/local/libexec/container-plugins/compose first if it is a directory.
    EOS
  end
end
