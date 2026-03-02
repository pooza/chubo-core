include_recipe 'client' if node.dig('mysql', 'client', 'enable')
include_recipe 'server' if node.dig('mysql', 'server', 'enable')
