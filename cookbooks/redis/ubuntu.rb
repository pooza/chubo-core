exit unless node.dig('redis', 'enable')
exit unless node.platform == 'ubuntu'

# Debian/Ubuntu の redis-server は apt 導入で systemd 有効化＋起動まで行い、
# /etc/redis/redis.conf も systemd 前提の適切な既定を持つため設定は上書きしない
# （FreeBSD 版の redis.conf.erb は daemonize/パス前提が異なり流用不可）。
package 'redis-server'

# パッケージ同梱の logrotate 設定は su も create も持たず、chubo が global に置いている
# `create 640 root <wheel>` を拾って redis が開けないログを作る。詳細はテンプレート冒頭の
# コメントと pooza/chubo2#202 を参照。
template '/etc/logrotate.d/redis-server' do
  source 'templates/logrotate.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

# 既に root 所有で作られてしまったログは copytruncate では直らない（所有者を引き継ぐため）。
# 収束のたびに所有者を戻しておかないと、次の再起動で redis が起動失敗する。
file '/var/log/redis/redis-server.log' do
  owner 'redis'
  group node.dig('wheel', 'group')
  mode '0660'
end

service 'redis-server' do
  action [:enable, :start]
end
