exit unless node.platform == 'ubuntu'

# ⚠⚠ **無人更新でサービスを一斉再起動しているのは unattended-upgrades ではなく
# needrestart。**ライブラリ更新のたびに「古い .so を掴んだままのプロセス」を洗い出し、
# APT フックとして走るときの既定モード `a`（automatic）で**無人・無告知に再起動する**。
#
# 2026-08-27 のダイスキー本番 53 分停止はこれが引き金だった（pooza/chubo2#204 / #202）。
# 🔴 **`Unattended-Upgrade::Package-Blacklist` は再起動を止めない。**あのとき redis-server は
# 既にブラックリストに入っていたが、更新されないまま**再起動だけされた**（libssl を掴んで
# いたため）。⚠ **栓はこのファイルにしかない。**
#
# ⚠ 代償: ここに挙げたサービスは**更新した libssl を掴み直さない**。
# `needrestart -r l` で再起動待ちを一覧できるので、**計画再起動で畳む**こと。
config = node.dig('needrestart', 'override_rc')
exit if config.nil? || config.empty?

# ⚠ unattended_upgrades と同じ方針で、**パッケージの新規導入はしない。**
# 無人更新が走っていないノードに栓だけ生やしても意味が無く、
# 「無人更新を新たに始めるか」は別の判断（pooza/chubo2#204）。
installed = 'dpkg -l needrestart 2>/dev/null | grep -q "^ii"'

# conf.d は辞書順に eval される。50 番台に置いて本体 needrestart.conf の既定の後に読ませる。
template '/etc/needrestart/conf.d/50chubo-needrestart.conf' do
  source 'templates/needrestart.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  variables(services: config)
  only_if installed
end
