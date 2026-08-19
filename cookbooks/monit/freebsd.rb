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
#
# ※ node は Hashie::Mash なので present? を使ってはいけない。Mash の method_missing が
#    `present?` を「present というキーがあるか」の述語として横取りし、中身に関係なく
#    常に false を返す。例外も出ないので、レシピが黙って何もしない形で壊れる。
filesystems = node.dig('monit', 'filesystems') || {}

unless filesystems.empty?
  template '/usr/local/etc/monit.d/disk' do
    source 'templates/disk.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end
end

# プロセス監視も node の宣言から生成する（pooza/chubo2#127）。
#
# ⚠ **既存の監視は手管理のファイル**（`monit.d/mastodon` 等）で、レシピは触らない。
# ⚠⚠ **ファイル名は check 名にする**ので、手管理側を宣言へ移すときは同名で上書きされる
# （移した後に古いファイルを消せば、check の二重定義にはならない）。
#
# ※ node は Hashie::Mash なので present? を使ってはいけない（上記の理由と同じ）。
processes = node.dig('monit', 'processes') || {}

processes.each do |name, config|
  template "/usr/local/etc/monit.d/#{name}" do
    source 'templates/process.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
    variables(name:, config:)
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
