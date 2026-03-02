exit unless node.platform == 'freebsd'

template '/boot/loader.conf' do
  source 'templates/loader.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end
