exit unless node.platform == 'freebsd'

template '/etc/freebsd-update.conf' do
  source 'templates/freebsd-update.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end
