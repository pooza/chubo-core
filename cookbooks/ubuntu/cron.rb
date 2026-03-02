exit unless node.platform == 'ubuntu'

template '/etc/crontab' do
  source 'templates/crontab.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end
