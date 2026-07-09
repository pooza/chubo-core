exit unless node.dig('ruby', 'version')

deployer = node.dig('deployer', 'user')
home = "/home/#{deployer}"
version = node.dig('ruby', 'version').to_s
global = (node.dig('ruby', 'global') || version).to_s

# YJIT を有効化するため Rust を先に用意してから rbenv でビルドする。
# rbenv install は not_if で「YJIT 有効なら実行しない」＝ YJIT 無効ビルドは --force で作り直す。
# itamae の execute は environment 属性を持たないため、環境変数はコマンド文字列に前置する。
case node.platform
when 'freebsd'
  # rbenv / ruby-build / ビルド依存（rust 含む）はすべて pkg で入る
  ['rbenv', 'ruby-build', 'autoconf', 'bison', 'readline', 'openssl',
   'libyaml', 'libffi', 'rust'].each do |pkg|
    package pkg
  end

  rbenv = 'rbenv'
  env = ''
  system_openssl_check = nil
when 'ubuntu'
  # apt に rbenv / ruby-build / rust が無いため git + rustup で用意する
  ['git', 'curl', 'build-essential', 'autoconf', 'bison', 'libssl-dev',
   'libreadline-dev', 'zlib1g-dev', 'libyaml-dev', 'libffi-dev',
   'libgdbm-dev', 'libncurses-dev', 'pkg-config'].each do |pkg|
    package pkg
  end

  rbenv_root = "#{home}/.rbenv"
  cargo_home = "#{home}/.cargo"
  rbenv = "#{rbenv_root}/bin/rbenv"

  # --with-openssl-dir=/usr で system OpenSSL に固定する。これが無いと
  # ruby-build が「system openssl が定義の上限より新しい」と判断して OpenSSL を
  # Ruby の prefix へ同梱ビルドしてしまい、同梱の古い libssl が先にロードされる。
  # その状態で system の共有ライブラリ（libvips → libcurl）を dlopen すると
  # `version OPENSSL_3.2.0 not found` で失敗する。
  env = "RBENV_ROOT=#{rbenv_root} RUBY_CONFIGURE_OPTS=--with-openssl-dir=/usr " \
    "PATH=#{rbenv_root}/bin:#{rbenv_root}/shims:#{cargo_home}/bin:/usr/local/bin:/usr/bin:/bin "
  # Ruby がリンクしている OpenSSL が system と一致するか。ずれていれば
  # OpenSSL を同梱ビルドした Ruby なので作り直す。
  ruby_openssl = "#{env}RBENV_VERSION=#{version} #{rbenv} exec " \
    "ruby -ropenssl -e 'print OpenSSL::OPENSSL_LIBRARY_VERSION.split[1]'"
  system_openssl_check = %(test "$(#{ruby_openssl})" = "$(openssl version | awk '{print $2}')")

  git rbenv_root do
    repository 'https://github.com/rbenv/rbenv.git'
    user deployer
  end

  git "#{rbenv_root}/plugins/ruby-build" do
    repository 'https://github.com/rbenv/ruby-build.git'
    user deployer
  end

  # Rust（rustup / 最小プロファイル）。YJIT のビルドに必要
  execute "install rustup for #{deployer}" do
    command "HOME=#{home} CARGO_HOME=#{cargo_home} RUSTUP_HOME=#{home}/.rustup " \
      "sh -c \"curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs " \
      '| sh -s -- -y --default-toolchain stable --profile minimal"'
    user deployer
    not_if "test -x #{cargo_home}/bin/rustc"
  end
else
  exit
end

# Ruby ビルド。YJIT がビルドに含まれていなければ --force で作り直す。
# RubyVM::YJIT.enabled? は「ランタイムで有効か」で既定 false のため、
# --yjit で起動して「ビルドに含まれるか」を判定する（含まれれば冪等に skip）。
# あわせて、過去に OpenSSL を同梱ビルドした Ruby も作り直す（上の env のコメント参照）。
guard = "#{env}RBENV_VERSION=#{version} #{rbenv} exec ruby --yjit -e 'exit RubyVM::YJIT.enabled?'"
guard += " && #{system_openssl_check}" if system_openssl_check

execute "rbenv install #{version} for #{deployer}" do
  command "#{env}#{rbenv} install --force #{version}"
  user deployer
  not_if guard
end

execute "rbenv global #{global} for #{deployer}" do
  command "#{env}#{rbenv} global #{global}"
  user deployer
  not_if "#{env}#{rbenv} global | grep -qx #{global}"
end

# ログインシェルで rbenv を有効化する。これが無いと login shell（rc.d の
# `bash -lc` 経由起動を含む）で shims が PATH に載らず OS 同梱 ruby に
# フォールバックし、意図した版で起動しない。本番と同じ 2 行を冪等に追記する。
execute "rbenv init for #{deployer} login shell" do
  command %(printf '%s\\n' 'export PATH="$HOME/.rbenv/bin:$PATH"' 'eval "$(rbenv init - bash)"' >> #{home}/.bash_profile)
  user deployer
  not_if "grep -q 'rbenv init' #{home}/.bash_profile 2>/dev/null"
end
