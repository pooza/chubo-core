exit unless node.dig('nvm', 'enable')

deployer = node.dig('deployer', 'user')
home = "/home/#{deployer}"
nvm_dir = "#{home}/.nvm"
version = node.dig('nvm', 'version')

package 'git'
package 'curl'

git nvm_dir do
  repository 'https://github.com/nvm-sh/nvm.git'
  revision node.dig('nvm', 'revision') || 'v0.40.3'
  user deployer
end

# nvm.sh は bash 前提。dash (/bin/sh) では動かないため bash で明示的に読み込む
if version
  nvm = %(export NVM_DIR="#{nvm_dir}"; . "$NVM_DIR/nvm.sh")

  execute "nvm install #{version} for #{deployer}" do
    command %(bash -c '#{nvm}; nvm install #{version} && nvm alias default #{version}')
    user deployer
    environment('HOME' => home)
    not_if %(bash -c '#{nvm}; nvm which #{version}')
  end
end
