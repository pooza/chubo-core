exit unless node.platform == 'freebsd'

package 'rsyslog'

execute 'sysrc syslogd_enable="NO"'
execute 'sysrc rsyslogd_enable="YES"'
execute 'sysrc rsyslogd_pidfile="/var/run/syslog.pid"'
execute 'sysrc devd_flags="-q"'

template '/usr/local/etc/rsyslog.conf' do
  source 'templates/rsyslog.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

directory '/usr/local/etc/rsyslog.d' do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0775'
end

directory '/usr/local/etc/newsyslog.conf.d' do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0775'
end

template '/etc/newsyslog.conf' do
  source 'templates/newsyslog.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

service 'syslogd' do
  action :stop
end
service 'rsyslogd' do
  action :restart
end

execute 'rm /var/log/*.bz2 || true'
[
  'cron',
  'daemon.log',
  'debug.log',
  'devd.log',
  'security',
  'ppp.log',
  'maillog',
  'lpd-errs',
  'xferlog',
].each do |mask|
  file File.join('/var/log', mask) do
    action :delete
  end
end
