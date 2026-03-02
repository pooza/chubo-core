include_recipe 'client' if node.dig('postgresql', 'client', 'enable')
include_recipe 'server' if node.dig('postgresql', 'server', 'enable')
