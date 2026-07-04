exit unless node.dig('ruby', 'version')

deployer = node.dig('deployer', 'user')
home = "/home/#{deployer}"
version = node.dig('ruby', 'version').to_s
global = (node.dig('ruby', 'global') || version).to_s

# YJIT を有効化するため Rust を先に用意してから rbenv でビルドする。
# rbenv install は not_if で「YJIT 有効なら実行しない」＝ YJIT 無効ビルドは --force で作り直す。
case node.platform
when 'freebsd'
  # rbenv / ruby-build / ビルド依存（rust 含む）はすべて pkg で入る
  ['rbenv', 'ruby-build', 'autoconf', 'bison', 'readline', 'openssl',
   'libyaml', 'libffi', 'rust'].each do |pkg|
    package pkg
  end

  rbenv = 'rbenv'
  rbenv_env = {}
when 'ubuntu'
  # apt に rbenv / ruby-build / rust が無いため git + rustup で用意する
  ['git', 'curl', 'build-essential', 'autoconf', 'bison', 'libssl-dev',
   'libreadline-dev', 'zlib1g-dev', 'libyaml-dev', 'libffi-dev',
   'libgdbm-dev', 'libncurses-dev'].each do |pkg|
    package pkg
  end

  rbenv_root = "#{home}/.rbenv"
  cargo_bin = "#{home}/.cargo/bin"
  rbenv = "#{rbenv_root}/bin/rbenv"
  rbenv_env = {
    'RBENV_ROOT' => rbenv_root,
    'PATH' => "#{rbenv_root}/bin:#{rbenv_root}/shims:#{cargo_bin}:/usr/local/bin:/usr/bin:/bin",
  }

  git rbenv_root do
    repository 'https://github.com/rbenv/rbenv.git'
    user deployer
  end

  git "#{rbenv_root}/plugins/ruby-build" do
    repository 'https://github.com/rbenv/ruby-build.git'
    user deployer
  end

  # Rust（rustup / 最小プロファイル）。YJIT のビルドに必要
  execute 'install rustup' do
    command "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs " \
      '| sh -s -- -y --default-toolchain stable --profile minimal'
    user deployer
    environment('HOME' => home)
    not_if "test -x #{cargo_bin}/rustc"
  end
else
  exit
end

# Ruby ビルド。YJIT 無効でビルド済みなら --force で作り直す
execute "rbenv install #{version} for #{deployer}" do
  command "#{rbenv} install --force #{version}"
  user deployer
  environment rbenv_env
  not_if "RBENV_VERSION=#{version} #{rbenv} exec ruby -e 'exit RubyVM::YJIT.enabled?'"
end

execute "rbenv global #{global} for #{deployer}" do
  command "#{rbenv} global #{global}"
  user deployer
  environment rbenv_env
  not_if "#{rbenv} global | grep -qx #{global}"
end
