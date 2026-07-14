exit unless node.platform == 'ubuntu'

# システム標準の Ruby を入れる。rbenv 版は別（cookbooks/ruby/default.rb）。
# バージョンは指定しない（ディストロ既定を使う意図。ruby.version は rbenv 用のため
# ここで apt パッケージ名に流用すると存在しない ruby<version> を叩いて死ぬ）。
package 'ruby'
package 'ruby-dev'
package 'libz-dev'
package 'libjemalloc-dev'

gem_package 'bundler'
gem_package 'rake'
