exit unless node.dig('monit', 'enable')
exit unless node.platform == 'freebsd'

package 'monit'

directory '/usr/local/etc/monit.d' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0775'
end

template '/usr/local/etc/monitrc' do
  source 'templates/monitrc.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0600'
end

# 監視対象のファイルシステムはノードによって違う（/var/db/postgres を別データセットに
# 切っている機とそうでない機がある）ので、node の monit.filesystems 宣言から生成する。
if node.dig('monit', 'filesystems').present?
  template '/usr/local/etc/monit.d/disk' do
    source 'templates/disk.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end
end

execute 'sysrc monit_enable="YES"'
service 'monit' do
  action [:start, :restart]
end

template '/usr/local/etc/rsyslog.d/monit.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

template '/usr/local/etc/newsyslog.conf.d/monit.conf' do
  source 'templates/newsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc rsyslogd_enable="YES"'
service 'rsyslogd' do
  action [:start, :restart]
end
