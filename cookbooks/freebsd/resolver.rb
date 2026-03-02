exit unless node.platform == 'freebsd'

template '/etc/hosts' do
  source 'templates/hosts.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

template '/etc/resolv.conf' do
  source 'templates/resolv.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end
