exit unless node.dig('docker', 'enable')
package 'ca-certificates'
package 'curl'
package 'gnupg'
package 'lsb-release'

directory '/etc/apt/keyrings' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end

file node.dig('docker', 'keyring', 'path') do
  action :delete
end
url = node.dig('docker', 'keyring', 'url')
path = node.dig('docker', 'keyring', 'path')
execute "curl -fsSL #{url} | gpg --dearmor -o #{path} || true"
file node.dig('docker', 'keyring', 'path') do
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

directory '/etc/apt/sources.list.d' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end
# ⚠ sources.list を置いただけでは apt のインデックスに入らない。これが無いと
# 直後の docker レシピが `E: パッケージ 'docker-ce' にはインストール候補がありません`
# で落ちる（ubuntu/packages を挟めば結果的に通るので、単体で流したときだけ踏む）。
execute 'apt update' do
  action :nothing
end

template '/etc/apt/sources.list.d/docker.list' do
  source 'templates/docker.list.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  notifies :run, 'execute[apt update]', :immediately
end
