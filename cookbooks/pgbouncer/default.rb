exit unless node.dig('pgbouncer', 'enable')
exit unless node.platform == 'freebsd'

package 'pgbouncer'

# ⚠⚠ pgbouncer を restart してはいけない。設定の反映は必ず reload（SIGHUP）で行う。
#
# FreeBSD の rc は stop で SIGTERM を送る（pgbouncer_sig_stop の既定が TERM）。
# ところがこの pgbouncer の SIGTERM は即時停止ではなく
# 「got SIGTERM, shutting down, waiting for all clients disconnect」＝ graceful drain で、
# Rails の長寿命接続（実測 age=5972s）が残っていると listener 不在のまま延々と待つ。
# その間 6432 への接続は Connection refused になり、Mastodon は全リクエストが
# PG::ConnectionBad → HTTP 500 に落ちる。
#
# 実際に 2026-08-08 11:45 の shallu で **5 分 46 秒の全断（HTTP 500 約 190 件）** を踏んだ。
# rc の gracefulstop は SIGINT でさらに待つので、そちらも使わない。
#
# reload で足りる根拠: SHOW CONFIG の changeable が yes の項目は SIGHUP で反映される。
# 本テンプレートが書くキーのうち max_client_conn / default_pool_size / pool_mode /
# auth_type / auth_file / admin_users / syslog* はすべて yes。changeable=no は
# listen_addr / listen_port / pidfile の 3 つだけで、いずれも node から動かない固定値。
# それらを変える必要が出たときだけ、窓を選んで手で restart すること。
template '/usr/local/etc/pgbouncer.ini' do
  source 'templates/pgbouncer.ini.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  notifies :run, 'execute[reload pgbouncer]'
end

execute 'reload pgbouncer' do
  command 'service pgbouncer reload'
  action :nothing
  only_if 'service pgbouncer status'
end

execute 'sysrc pgbouncer_enable="YES"'

# 落ちていれば起動する。restart は上記の理由で行わない。
service 'pgbouncer' do
  action [:start]
end

template '/usr/local/etc/rsyslog.d/pgbouncer.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  notifies :restart, 'service[rsyslogd]'
end

template '/usr/local/etc/newsyslog.conf.d/pgbouncer.conf' do
  source 'templates/newsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc rsyslogd_enable="YES"'

# こちらも無条件 restart をやめる。差分が無いのにサービスを触ると、
# 「2 回目の適用で差分 0」が成り立たなくなり、レシピの再実行が怖くなる。
service 'rsyslogd' do
  action [:start]
end

template '/usr/local/etc/monit.d/pgbouncer' do
  source 'templates/monit.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  only_if 'test -d /usr/local/etc/monit.d'
end

execute 'monit reload' do
  only_if 'service monit status'
end
