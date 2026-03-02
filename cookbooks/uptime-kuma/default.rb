exit unless node.dig('uptime-kuma', 'enable')

include_recipe 'nginx'
include_recipe 'logging'
include_recipe 'repos'
