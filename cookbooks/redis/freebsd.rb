exit unless node.dig('redis', 'enable')
exit unless node.platform == 'freebsd'

package 'redis'

template '/usr/local/etc/redis.conf' do
  source 'templates/redis.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc redis_enable="YES"'
service 'redis' do
  action [:start, :restart]
end

template '/usr/local/etc/rsyslog.d/redis.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

template '/usr/local/etc/newsyslog.conf.d/redis.conf' do
  source 'templates/newsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc rsyslogd_enable="YES"'
service 'rsyslogd' do
  action [:start, :restart]
end

template '/usr/local/etc/monit.d/redis' do
  source 'templates/monit.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  only_if 'test -d /usr/local/etc/monit.d'
end

execute 'monit reload' do
  only_if 'service monit status'
end
