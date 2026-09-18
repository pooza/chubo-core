exit unless node.platform == 'freebsd'

# ⚠⚠ **rc.conf にアドレスを手書きしない（pooza/chubo2#239）。**
#
# pirazal / pirazis だけが `ifconfig_vtnet0="inet <IP> netmask ..."` と
# `defaultrouter` を手書きで持っていた。**クローン・レスキュー・リサイズのたびに
# 手当てが要る**状態で、実際に #237 の検証で **pirazis のクローンがネットワークに
# 出てこなかった**（クローン元の IP のまま起動し、Linode の anti-spoofing に黙って落とされる）。
# 復旧には Lish でシングルユーザに落とす必要があった。
# ⚠ **Linode の Network Helper は効かない**（この FreeBSD イメージは対象外・実測）。
#
# ⚠ **静的にする理由は無い。**Linode の DHCP は MAC に紐づいた予約制で、
# IPv6 も EUI-64 の SLAAC なので **同じアドレスが返る**（2026-09-18 に 2 台で実測）。
#
# ⚠⚠ **自宅側（dev24-26 / seas の em0）は対象外。**あちらは LAN の静的運用で、
# クローンもレスキューも起きない。**宣言したノードだけが対象**なのはそのため。
config = node['network']
exit unless config

interface = config['interface']
raise 'network.interface が無い' unless interface

execute "sysrc ifconfig_#{interface}=DHCP"

# ⚠⚠ **`accept_rtadv` だけでは足りない。**RA を受け取る口は開くが、
# **自分から送出（router solicitation）しないので、最初の RA が来るまで
# グローバル IPv6 が付かない。**受動受信でもいずれ付くが、ルータの RA 間隔
# 次第で数分かかる。⚠ **権威 DNS や SNS は再起動直後から AAAA が生きている必要がある**ので
# rtsold を必ず動かす（2026-09-18 に pirazis で、再起動 1 分後もアドレスが無いのを実測）。
execute %(sysrc ifconfig_#{interface}_ipv6="inet6 accept_rtadv")
execute 'sysrc rtsold_enable=YES'

service 'rtsold' do
  action [:enable, :start]
end

# ⚠ デフォルト経路は DHCP と RA が配る。手書きは消す。
# ⚠⚠ **`ipv6_defaultrouter="fe80::1"` は古い。**2026-09-18 の実測では RA が広告するのは
# `fe80::a9fe:a9fe` で、**手書きと違うアドレス**だった。2 本のデフォルト経路が並ぶ。
['defaultrouter', 'ipv6_defaultrouter'].each do |key|
  execute "sysrc -x #{key}" do
    # ⚠ 無いキーへ `sysrc -x` を撃つと落ちるので、あるときだけ。
    only_if "sysrc -n #{key} > /dev/null 2>&1"
  end
end

# ⚠⚠ **`service netif restart` はしない。**SSH 越しだと切れて戻れなくなる
# （#239 の手順にも明記）。**反映は再起動で確認する。**
