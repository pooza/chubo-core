exit unless node.dig('uptime-kuma', 'enable')

template "/etc/nginx/servers/#{node.dig('uptime-kuma', 'host')}.conf" do
  source 'templates/nginx.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0664'
end

service 'nginx' do
  action :restart
end
service 'rsyslog' do
  action :restart
end
