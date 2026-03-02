exit unless node.platform == 'freebsd'

template '/etc/ssh/sshd_config' do
  source 'templates/sshd_config.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

template '/etc/ssh/ssh_config' do
  source 'templates/ssh_config.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

service 'sshd' do
  action :restart
end
