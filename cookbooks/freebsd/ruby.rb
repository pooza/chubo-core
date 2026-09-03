exit unless node.platform == 'freebsd'

# ⚠⚠ ここが見るのは **pkg / ports の版**（`ruby34-gems`）で、rbenv でビルドする版とは別物。
# 1 つの `ruby.version` に両方を背負わせていたときは、`4.0.6` から存在しない
# `ruby406-gems` を組んで **本番 gomander で落ちていた**（pooza/chubo2#71）。
version = node.dig('ruby', 'system', 'version')
exit unless version

package "ruby#{version.to_s.delete('.')}-gems"

gem_package 'bundler'
gem_package 'rake'
