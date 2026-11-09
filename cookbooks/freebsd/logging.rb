exit unless node.platform == 'freebsd'

# rsyslog.d / newsyslog.conf.d のグループ。既定は wheel.group（今までどおり）。
# サイトのアカウントがこの置き場へ設定を書く利用側（chubo-minc: minc3 / kariyon の rake install）は operator などを宣言する。
# 宣言しないと、利用側のレシピと適用のたびに書き換え合う（pooza/chubo-minc#35）。
conf_dir_group = node.dig('logging', 'conf_dir_group') || node.dig('wheel', 'group')

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
  group conf_dir_group
  mode '0775'
end

directory '/usr/local/etc/newsyslog.conf.d' do
  owner 'root'
  group conf_dir_group
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
