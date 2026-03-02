exit unless node.platform == 'freebsd'

template '/usr/local/etc/periodic/hourly/900.ntpdate' do
  source 'templates/ntpdate.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0755'
end
