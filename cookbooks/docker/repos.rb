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

# apt のサードパーティ suite 名（codename）。⚠⚠ **yaml の `release` より実機の `/etc/os-release` を優先する**
# （pooza/chubo-core#20）。platform yaml に 1 つだけ書くと、版の違う機（例: 26.04 の中の 24.04）が
# **黙って一世代前の suite を掴み続ける**。明示の `docker.source.suite` があればそれが最優先
# （上流がまだ新しい codename を配っていないときの逃げ道）。`release` は取れなかったときの予備。
os_codename = run_command('. /etc/os-release && echo "$VERSION_CODENAME"', error: false).stdout.strip
docker_suite = node.dig('docker', 'source', 'suite') || (os_codename.empty? ? node.release : os_codename)

template '/etc/apt/sources.list.d/docker.list' do
  source 'templates/docker.list.erb'
  variables(suite: docker_suite)
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  notifies :run, 'execute[apt update]', :immediately
end
