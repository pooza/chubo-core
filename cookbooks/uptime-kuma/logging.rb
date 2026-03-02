exit unless node.dig('uptime-kuma', 'enable')

template '/etc/rsyslog.d/nginx_uptime-kuma.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0664'
end
service 'rsyslog' do
  action :restart
end
