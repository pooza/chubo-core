exit unless node.dig('docker', 'enable')

# ⚠ apt リポジトリを置くのはこの recipe ではなく repos.rb なので、include しないと
# `--recipes=docker` を単体で流したときに
# `E: パッケージ 'docker-ce' にはインストール候補がありません` で落ちる
# （pooza/chubo-core#19）。⚠⚠ 既存ノードは過去に手で流した docker.list の上に
# 乗っているため、この穴は新規構築でしか露見しない（leech / mucor で踏んだ）。
# ⚠ repos.rb 側は docker.list を書き換えたときだけ `apt update` を走らせる
# （notifies）ので、毎回 include しても余計な更新は起きない。
include_recipe 'repos'

package 'docker-ce'
package 'docker-ce-cli'
package 'containerd.io'
package 'docker-compose-plugin'

link '/usr/local/bin/docker-compose' do
  to '/usr/libexec/docker/cli-plugins/docker-compose'
  force true
end
