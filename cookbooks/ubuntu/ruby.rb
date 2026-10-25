exit unless node.platform == 'ubuntu'

# システム標準の Ruby を入れる。rbenv 版は別（cookbooks/ruby/default.rb）。
# バージョンは指定しない（ディストロ既定を使う意図。ruby.rbenv.version は rbenv 用のため
# ここで apt パッケージ名に流用すると存在しない ruby<version> を叩いて死ぬ）。
package 'ruby'
package 'ruby-dev'
# ⚠ libz-dev は仮想パッケージ。itamae は dpkg で実体を見るので、入っていても毎回「未導入」と出る
# （全 Ubuntu ノードで偽のドリフトになっていた・pooza/chubo2#121）。実体の名前で書く。
package 'zlib1g-dev'
package 'libjemalloc-dev'

gem_package 'bundler'
gem_package 'rake'
