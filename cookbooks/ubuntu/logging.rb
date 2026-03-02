exit unless node.platform == 'ubuntu'
package 'rsyslog'

template '/etc/rsyslog.conf' do
  source 'templates/rsyslog.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

directory '/etc/rsyslog.d' do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0775'
end

template '/etc/logrotate.conf' do
  source 'templates/logrotate.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

directory '/etc/logrotate.d' do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0775'
end
template '/etc/logrotate.d/main' do
  source 'templates/logrotate.d/main.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

# /var/log のgroupを変更しないとlogrotateが動かない
directory '/var/log' do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0755'
end

# AppArmorを無効化しないと、ログファイルのグループ変更ができない
link '/etc/apparmor.d/disable/usr.sbin.rsyslogd' do
  to '/etc/apparmor.d/usr.sbin.rsyslogd'
end
execute 'apparmor_parser -R /etc/apparmor.d/usr.sbin.rsyslogd || true'

# rsyslogのサービスに`UMask=0027`を設定しないと、ログファイルのパーミッションが`0640`にならない
directory '/etc/systemd/system/rsyslog.service.d' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end
template '/etc/systemd/system/rsyslog.service.d/override.conf' do
  source 'templates/rsyslog.service.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end
execute 'systemctl daemon-reload'

[
  '/etc/rsyslog.d/20-ufw.conf',
  '/etc/rsyslog.d/21-cloudinit.conf',
  '/etc/rsyslog.d/50-default.conf',
  '/etc/logrotate.d/rsyslog',
  '/etc/logrotate.d/wtmp',
  '/etc/logrotate.d/btmp',
].each do |path|
  file path do
    action :delete
  end
end

service 'rsyslog' do
  action [:enable, :restart]
end
