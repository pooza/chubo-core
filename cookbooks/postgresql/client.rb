exit unless node.dig('postgresql', 'client', 'enable')

package "postgresql-client-#{node.dig('postgresql', 'version')}"
