exit unless node.platform == 'ubuntu'

package "ruby#{node.dig('ruby', 'version')}"
package 'ruby-dev'
package 'libz-dev'
package 'libjemalloc-dev'

gem_package 'bundler'
gem_package 'rake'
