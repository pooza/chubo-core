exit unless node.dig('wikijs', 'enable')

template '/etc/rsyslog.d/nginx_wikijs.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0664'
end
service 'rsyslog' do
  action :restart
end
