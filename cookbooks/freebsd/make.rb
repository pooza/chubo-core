exit unless node.platform == 'freebsd'

template '/etc/make.conf' do
  source 'templates/make.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end
