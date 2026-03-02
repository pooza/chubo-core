exit if !node.dig('postgresql', 'server', 'enable') && !node.dig('postgresql', 'client', 'enable')

directory '/etc/apt/sources.list.d' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end
template '/etc/apt/sources.list.d/postgresql.list' do
  source 'templates/postgresql.list.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -' do
  not_if 'apt-key list | grep -q "PostgreSQL Debian Repository"'
end
