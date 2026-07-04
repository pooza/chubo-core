exit unless node.dig('redis', 'enable')
exit unless node.platform == 'ubuntu'

# Debian/Ubuntu の redis-server は apt 導入で systemd 有効化＋起動まで行い、
# /etc/redis/redis.conf も systemd 前提の適切な既定を持つため設定は上書きしない
# （FreeBSD 版の redis.conf.erb は daemonize/パス前提が異なり流用不可）。
package 'redis-server'

service 'redis-server' do
  action [:enable, :start]
end
