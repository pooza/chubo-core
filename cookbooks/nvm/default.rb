exit unless node.dig('nvm', 'enable')

deployer = node.dig('deployer', 'user')
home = "/home/#{deployer}"
nvm_dir = "#{home}/.nvm"
version = node.dig('nvm', 'version')
revision = node.dig('nvm', 'revision') || 'v0.40.3'

package 'git'
package 'curl'

# nvm は公式 install.sh で導入する（NVM_DIR は既定の ~/.nvm）。
# PROFILE=/dev/null でシェル rc への追記を抑止（rc は zsh cookbook が管理）。
# itamae の execute は environment 属性を持たないため env はコマンドに前置する。
execute "install nvm for #{deployer}" do
  command %(HOME=#{home} PROFILE=/dev/null bash -c ) +
          %('curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/#{revision}/install.sh | bash')
  user deployer
  not_if "test -s #{nvm_dir}/nvm.sh"
end

if version
  nvm = %(export NVM_DIR="#{nvm_dir}"; . "$NVM_DIR/nvm.sh")

  execute "nvm install #{version} for #{deployer}" do
    command %(HOME=#{home} bash -c '#{nvm}; nvm install #{version} && nvm alias default #{version}')
    user deployer
    not_if %(HOME=#{home} bash -c '#{nvm}; nvm which #{version}')
  end
end
