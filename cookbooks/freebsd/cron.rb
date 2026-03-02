exit unless node.platform == 'freebsd'

package 'anacron'

template '/etc/crontab' do
  source 'templates/crontab.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

template '/etc/periodic.conf' do
  source 'templates/periodic.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

['hourly', 'daily', 'weekly', 'monthly'].each do |period|
  directory File.join('/usr/local/etc/periodic', period) do
    owner 'root'
    group node.dig('sudo', 'group')
    mode '0775'
  end
end
