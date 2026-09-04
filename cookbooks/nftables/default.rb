# Ubuntu / Debian のホスト firewall。⚠ **ufw ではなく nftables を直に持つ。**
#
# ufw の状態は自前の DB に散るので宣言と実機を突き合わせられない。nftables なら
# /etc/nftables.conf の 1 枚がそのまま実効ルールで、`nft -c -f` で検査もできる
# （pooza/chubo2#200 / #121）。nftables.service は Debian 系の既定で enable 済み。
#
# input は **policy drop**。ここに書いた allow だけが入ってくるので、
# 「書かないこと」がそのまま「閉じていること」を意味する。
#
# 🔴 このレシピは nftables をリロードしない。理由は default.rb 末尾のコメント。
exit unless node.dig('nftables', 'enable')
exit unless node.platform == 'ubuntu'

# ⚠ ここが空だと SSH ごと閉じる。空のまま流させない。
allow = Array(node.dig('nftables', 'allow'))
raise 'nftables.allow が空です。SSH ごと閉じます。' if allow.empty?

rules = allow.map do |entry|
  proto = (entry['proto'] || 'tcp').to_s
  raise "nftables.allow: 未対応の proto #{proto}" unless ['tcp', 'udp'].include?(proto)

  port = entry['port']
  raise 'nftables.allow: port が未設定です。' if port.to_s.empty?

  # from を省略／'any' にすると送信元を絞らない。⚠ 省略は「どこからでも」の意味に
  # なるので、絞りたいときは必ず書く。
  sources = Array(entry['from']).map(&:to_s).reject(&:empty?)
  sources = [] if sources == ['any']
  v6, v4 = sources.partition {|s| s.include?(':')}

  {proto:, port: port.to_s, v4:, v6:, comment: entry['comment'].to_s}
end

package 'nftables'

template '/etc/nftables.conf' do
  source 'templates/nftables.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  # 実行ビットは Debian の配布版に合わせる（`nft -f` のシバンを持つ）。
  mode '0755'
  variables(rules:)
end

# ⚠ 生成物が nftables として読めることだけは自動で見る。テンプレートの書き損じは
# ここで捕まる。⚠⚠ `-c` は**適用せずに構文検査だけ**行う。
execute 'verify /etc/nftables.conf' do
  command 'nft -c -f /etc/nftables.conf'
end

service 'nftables' do
  action :enable
end

# 🔴 `systemctl reload nftables` はこのレシピからは実行しない。
#
# 生成物は `flush ruleset` から始まるので、allow の書き漏らしがあると **その場で
# SSH が切れる**。app/cookbooks/ipfw（seas）と同じ考え方で、危険な一手はレシピの
# 副作用にしない。
#
# 適用したら、**保険を仕掛けてから**手で流すこと:
#
#   ssh <node> 'sudo sh -c "(sleep 60; nft flush ruleset) >/dev/null 2>&1 &"'
#   ssh <node> 'sudo systemctl reload nftables'
#   # 別セッションで疎通を確認できたら、保険の sh を pkill する
