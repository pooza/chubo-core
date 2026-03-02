exit unless node.platform == 'freebsd'

package "ruby#{node.dig('ruby', 'version').to_s.delete('.')}-gems"

gem_package 'bundler'
gem_package 'rake'
