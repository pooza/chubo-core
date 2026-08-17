# ZFS on Linux。⚠ FreeBSD の arc_max は freebsd/templates/loader.conf.erb が焼くので、
# こちらは Linux の modprobe.d を持つ。node の zfs.arc_max は両者で共有する。
# ⚠ プールとデータセットの作成はレシピの仕事ではない（一度きりの手作業。pooza/chubo2#35）。
exit unless node.platform == 'ubuntu'
exit unless (arc_max = node.dig('zfs', 'arc_max'))

# ⚠ loader.conf は "2G" のような接尾辞を解釈するが、modprobe の zfs_arc_max は
# バイト数の整数しか受け付けない。node yaml は FreeBSD と同じ書き方で通す。
matches = arc_max.to_s.strip.match(/\A(\d+)([KMGT])?B?\z/i)
raise "Invalid zfs.arc_max: #{arc_max}" unless matches
units = {'K' => 1024, 'M' => 1024**2, 'G' => 1024**3, 'T' => 1024**4}
arc_max_bytes = matches[1].to_i * (units[matches[2].to_s.upcase] || 1)

package 'zfsutils-linux'

template '/etc/modprobe.d/zfs.conf' do
  source 'templates/modprobe.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  variables(arc_max_bytes:)
end

# ⚠ modprobe.d はモジュール読み込み時にしか効かない。root が ext4 なら initramfs の
# 再生成は不要だが、そのぶん再起動まで値が変わらないので実行中の値も揃えておく。
execute "set zfs_arc_max to #{arc_max_bytes}" do
  command "echo #{arc_max_bytes} > /sys/module/zfs/parameters/zfs_arc_max"
  only_if 'test -f /sys/module/zfs/parameters/zfs_arc_max'
  not_if %(test "$(cat /sys/module/zfs/parameters/zfs_arc_max)" -eq #{arc_max_bytes})
end

# PostgreSQL のデータディレクトリが ZFS データセットのとき、zfs-mount.service より先に
# 起動すると空のマウントポイントを掴んで失敗する（infra-note「ZFS マウント順序の安定化」、
# sweep で実障害になった経路）。
# ⚠ drop-in はテンプレートユニット側に置く。systemd は postgresql@18-main に
# postgresql@.service.d の drop-in も併せて適用するので、PG のメジャー版に依存しない
# （vulcan で systemctl cat / systemctl show -p Requires まで確認済み）。
if node.dig('postgresql', 'server', 'enable')
  directory '/etc/systemd/system/postgresql@.service.d' do
    owner 'root'
    group node.dig('root', 'group')
    mode '0755'
  end

  template '/etc/systemd/system/postgresql@.service.d/zfs.conf' do
    source 'templates/postgresql.service.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end

  execute 'systemctl daemon-reload'
end
