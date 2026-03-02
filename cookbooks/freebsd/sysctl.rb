exit unless node.platform == 'freebsd'

template '/etc/sysctl.conf' do
  source 'templates/sysctl.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end
