exit unless node.dig('pgbouncer', 'enable')
exit unless node.platform == 'freebsd'

package 'pgbouncer'

template '/usr/local/etc/pgbouncer.ini' do
  source 'templates/pgbouncer.ini.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc pgbouncer_enable="YES"'
service 'pgbouncer' do
  action [:start, :restart]
end

template '/usr/local/etc/rsyslog.d/pgbouncer.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

template '/usr/local/etc/newsyslog.conf.d/pgbouncer.conf' do
  source 'templates/newsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc rsyslogd_enable="YES"'
service 'rsyslogd' do
  action [:start, :restart]
end
