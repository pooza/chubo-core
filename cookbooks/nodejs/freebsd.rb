exit unless node.dig('nodejs', 'enable')
exit unless node.platform == 'freebsd'

package "npm-node#{node.dig('nodejs', 'version')}"
package "node#{node.dig('nodejs', 'version')}"
execute 'corepack enable'
