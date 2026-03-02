exit unless node.dig('wikijs', 'enable')

template "/etc/nginx/servers/#{node.dig('wikijs', 'host')}.conf" do
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
