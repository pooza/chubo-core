exit unless node.dig('mysql', 'server', 'enable')

path = node.dig('mysql', 'server', 'config_path')
service_name = node.dig('mysql', 'server', 'service')

directory File.dirname(path) do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0755'
end

# ⚠ 変更が無いときに再起動しないこと。mysqld を落とすとそれに乗っているアプリ
# （pirazal / pirazis なら PowerDNS）が一時的にバックエンドを失う。
template path do
  source 'templates/my.cnf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
  notifies :restart, "service[#{service_name}]"
end

service service_name do
  action :nothing
end
