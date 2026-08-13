exit unless node.platform == 'freebsd'

# ⚠ config/platform/freebsd.yaml の timezone は、これを読む cookbook が無く
# 宣言だけの状態だった（pooza/chubo2#116）。Ubuntu 側は ubuntu/default.rb の
# timedatectl で効いている。
#
# 冪等判定に /var/db/zoneinfo を使う。FreeBSD には timedatectl のような
# 「現在のゾーン名」を問い合わせる手段が無く、/etc/localtime はバイナリなので
# 名前が読めない。tzsetup は入れたゾーン名をこのファイルに残す。
#
# ⚠ tzsetup を通さず /etc/localtime を手でコピーしたホストにはこのファイルが
# 無い（flauros / sweep が該当）。その場合も「不一致」として適用されるので、
# 手書き残置が tzsetup 経由に揃う（pooza/chubo2#110）。
execute "tzsetup -s #{node.timezone}" do
  not_if %(test "$(cat /var/db/zoneinfo 2>/dev/null)" = "#{node.timezone}")
end
