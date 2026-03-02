exit unless node.dig('wikijs', 'enable')

include_recipe 'nginx'
include_recipe 'logging'
include_recipe 'repos'
