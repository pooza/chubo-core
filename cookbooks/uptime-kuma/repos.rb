exit unless node.dig('uptime-kuma', 'enable')

dir = node.dig('uptime-kuma', 'path')
dir.gsub!('__USER__', node.dig('deployer', 'user'))

git dir do
  repository node.dig('uptime-kuma', 'repos')
  user node.dig('deployer', 'user')
end

# ⚠ `docker compose up -d` の既定 pull policy は `missing`（ローカルにイメージが
# あれば取り直さない）。したがって pull を書かないと、レシピを何度流してもイメージは
# 取得時点のまま固定され、上流のパッチが入らない（pooza/chubo2#219）。
#
# ⚠⚠ **これは compose 側でタグを固定してあることが前提。**`:latest` や `:2` のような
# 動くタグのまま無条件 pull を入れると、宣言を変えていないのにメジャーが上がりうる。
# タグ固定と pull は対で入れること。
execute 'docker compose pull' do
  cwd dir
end

execute 'docker compose up -d' do
  cwd dir
end
