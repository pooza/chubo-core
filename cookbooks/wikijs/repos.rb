exit unless node.dig('wikijs', 'enable')

dir = node.dig('wikijs', 'path')
dir.gsub!('__USER__', node.dig('deployer', 'user'))

# ⚠⚠ **共有リポジトリは、追随していない側では「上げる」変更になる**
# （pooza/chubo2#225）。`THE-POWERNEWS/uptime-kuma-docker` は chubo2 と
# writersbase-env が同じものを指しており、**片方が「動くタグを固定する」commit を
# 入れると、古い clone を持つもう片方では次にレシピを流した瞬間にメジャーが上がる。**
# 宣言を 1 行も変えていないのに動く、というのが危ないところ。
#
# ⚠ **`revision` を宣言できるようにしてある。**指定しなければ従来どおり既定ブランチの
# 先端に追随する（既存ノードの挙動は変わらない）。**共有リポジトリを指すノードでは
# 刺しておくと、上流の commit が勝手に効かない。**
revision = node.dig('wikijs', 'revision')

git dir do
  repository node.dig('wikijs', 'repos')
  revision revision if revision
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
