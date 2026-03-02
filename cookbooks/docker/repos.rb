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
template '/etc/apt/sources.list.d/docker.list' do
  source 'templates/docker.list.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end
