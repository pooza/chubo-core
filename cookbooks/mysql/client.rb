exit unless node.dig('mysql', 'client', 'enable')

package "mysql-client-core-#{node.dig('mysql', 'version')}"
