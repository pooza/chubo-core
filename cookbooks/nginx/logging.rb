exit unless node.dig('nginx', 'enable')

rsyslog_dir = node.platform == 'freebsd' ? '/usr/local/etc/rsyslog.d' : '/etc/rsyslog.d'

template "#{rsyslog_dir}/nginx.conf" do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

# vhost を置いた者が、その access ログを回収する。config.rb が生成する proxy vhost の
# tag はこの cookbook が所有しているので、対応する per-tag ルールもここで出す。
# 自分が書いていない tag を拾う catch-all（:programname, startswith, "nginx_" 等）は
# 置かないこと。tag を所有する他の cookbook（wikijs, uptime-kuma, matrix 等）のルールと
# 両方が発火し、二重書き込みになる。
#
# ⚠ **手管理の vhost が使っている tag は node yaml の `nginx.access_logs` で宣言する**
# （pooza/chubo2#67）。層1 の vhost をまだ cookbook 化できていない機体では tag を所有する
# cookbook が存在せず、access ログが `/var/log/messages` にしか残らない。catch-all は
# 上記の理由で置けないので、**宣言された tag だけを明示的に拾う**。
# ⚠ これは vhost 自体が cookbook 化されるまでの暫定で、cookbook 化したらそちらへ移すこと。
access_logs = (node.dig('nginx', 'proxies') || []) + (node.dig('nginx', 'access_logs') || [])
access_logs.each do |access_log|
  template "#{rsyslog_dir}/#{access_log['tag']}.conf" do
    source 'templates/rsyslog_access_log.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
    variables(access_log: access_log)
  end
end

# access ログの保持期間。⚠ **宣言しない限り掃除しない**（既定は無期限）。
# error ログは newsyslog / logrotate が世代で回すが、access ログは日付名で毎日
# 新しいファイルが生まれるため世代管理に載らず、圧縮されるだけで誰も消していなかった
# （pooza/chubo2#142）。掃除は不可逆なので、日数は node / platform yaml で明示させる。
retention_days = node.dig('nginx', 'access_log_retention_days').to_i
# ⚠ FreeBSD は periodic の実行順を数字で決める。圧縮（901）より後に置く。
cleanup_script = if node.platform == 'freebsd'
                   '/usr/local/etc/periodic/daily/910.nginx-access-log-cleanup'
                 else
                   '/etc/cron.daily/nginx-access-log-cleanup'
                 end

if retention_days.positive?
  template cleanup_script do
    source 'templates/cleanup_access_log.sh.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0755'
    variables(days: retention_days)
  end
else
  file cleanup_script do
    action :delete
  end
end

case node.platform
when 'freebsd'
  template '/usr/local/etc/newsyslog.conf.d/nginx.conf' do
    source 'templates/newsyslog.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end

  execute 'sysrc rsyslogd_enable="YES"' do
    not_if 'sysrc -n rsyslogd_enable 2>/dev/null | grep -qi "^yes$"'
  end
  service 'rsyslogd' do
    action [:start, :restart]
  end
when 'ubuntu'
  [
    '/var/log/nginx/error.log',
    '/var/log/nginx/access.log',
  ].each do |path|
    file path do
      action :delete
    end
  end

  service 'rsyslog' do
    action :restart
  end

  template '/etc/logrotate.d/nginx' do
    source 'templates/logrotate.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end
end
