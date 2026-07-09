exit unless node.dig('nvm', 'enable')

deployer = node.dig('deployer', 'user')
home = "/home/#{deployer}"
nvm_dir = "#{home}/.nvm"
revision = node.dig('nvm', 'revision') || 'v0.40.3'

# nvm.versions（配列）で複数版を共存させられる。nvm.version（スカラ）は従来互換。
# Misskey のように .node-version が上がる前提のアプリでは、旧版を残したまま
# 新版を入れてサービスの NODE_VERSION だけ差し替えられる形にしておく。
versions = Array(node.dig('nvm', 'versions') || node.dig('nvm', 'version')).map(&:to_s)
default = (node.dig('nvm', 'default') || versions.first)&.to_s

package 'git'
package 'curl'

# nvm は公式 install.sh で導入する（NVM_DIR は既定の ~/.nvm）。
# PROFILE=/dev/null でシェル rc への追記を抑止（rc は本 cookbook と zsh cookbook が管理）。
# itamae の execute は environment 属性を持たないため env はコマンドに前置する。
execute "install nvm for #{deployer}" do
  command %(HOME=#{home} PROFILE=/dev/null bash -c ) +
          %('curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/#{revision}/install.sh | bash')
  user deployer
  not_if "test -s #{nvm_dir}/nvm.sh"
end

nvm = %(export NVM_DIR="#{nvm_dir}"; . "$NVM_DIR/nvm.sh")

versions.each do |version|
  execute "nvm install #{version} for #{deployer}" do
    command %(HOME=#{home} bash -c '#{nvm}; nvm install #{version}')
    user deployer
    not_if %(HOME=#{home} bash -c '#{nvm}; nvm which #{version}')
  end
end

if default
  execute "nvm alias default #{default} for #{deployer}" do
    command %(HOME=#{home} bash -c '#{nvm}; nvm alias default #{default}')
    user deployer
    not_if %(HOME=#{home} bash -c '#{nvm}; test "$(nvm version default)" = "$(nvm version #{default})"')
  end
end

# ログインシェルで nvm を有効化する。deployer の login shell は zsh だが、
# systemd unit や rc.d は `bash -lc` を通るため .bash_profile も要る。
# 片方だけだと必ずどちらかで node が PATH に載らない（zsh 側は zsh cookbook が担当）。
init_lines = [
  'export NVM_DIR="$HOME/.nvm"',
  '[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"',
].map {|line| "'#{line}'"}.join(' ')

execute "nvm init for #{deployer} login shell" do
  command "printf '%s\\n' #{init_lines} >> #{home}/.bash_profile"
  user deployer
  not_if "grep -q 'NVM_DIR' #{home}/.bash_profile 2>/dev/null"
end
