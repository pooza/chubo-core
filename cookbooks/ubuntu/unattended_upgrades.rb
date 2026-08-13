exit unless node.platform == 'ubuntu'

# ⚠ Ubuntu の unattended-upgrades は素のままだと **noble アーカイブ全体**が対象で、
# セキュリティ修正以外の更新も無人で入る（pooza/chubo2#166）。2026-08-12 に sweep で
# systemd の更新に巻き添えられて redis-server が再起動し、モロヘイヤの Sidekiq が
# 1 秒間に 8 イベントの接続エラーを出した。
#
# 方針（2026-08-13 決定）:
#   - Allowed-Origins は **-security 系のみ**に絞る
#   - 地雷付きのサービス（PostgreSQL / pgbouncer / Redis）は Package-Blacklist で
#     除外し、**人が手順を読んでから**更新する。⚠ pgbouncer は restart 禁止
#     （infra-note「pgbouncer」）、sweep の PostgreSQL は起動時 ZFS import の地雷を持つ
#   - Automatic-Reboot は明示的に false（既定も false だが、暗黙に頼らない）
config = node['unattended_upgrades']
exit unless config

# ⚠⚠ **パッケージを新規導入はしない。**本レシピの目的は「既に無人で走っているものを
# 意図した設定に絞る」ことで、無人更新を新たに始めることではない。
#
# 2026-08-13 実測: unattended-upgrades が入っているのは **flauros / kues / sweep の
# 3 台だけ**で、LXC CT 10 台（leech / oscura / bydo / triton / mucor / conger / noah /
# dev27 / scylla / rubicon）には入っていない（CT の Ubuntu テンプレートに含まれない）。
# ⚠ `apt-daily-upgrade.timer` は全台 enabled だが、パッケージが無ければ何もしない。
# **CT 側にセキュリティ自動更新を新規導入するかは別の判断**なので、本レシピでは触らない。
installed = 'dpkg -l unattended-upgrades 2>/dev/null | grep -q "^ii"'

# ⚠ apt.conf.d は辞書順に読まれ、**リストは後勝ちではなく追記**される。既定の
# 50unattended-upgrades が入れた Allowed-Origins を消すには `#clear` が要る。
# ファイル名を 52 にしているのは 50unattended-upgrades より後に読ませるため。
template '/etc/apt/apt.conf.d/52chubo-unattended-upgrades' do
  source 'templates/unattended-upgrades.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  variables(config:)
  only_if installed
end

# apt-daily-upgrade.timer が実際に unattended-upgrade を呼ぶかどうか。
template '/etc/apt/apt.conf.d/20auto-upgrades' do
  source 'templates/auto-upgrades.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  variables(config:)
  only_if installed
end
