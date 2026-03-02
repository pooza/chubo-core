exit unless node.dig('redis', 'enable')

include_recipe node.platform
