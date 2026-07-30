exit unless node.dig('unbound', 'enable')

include_recipe node.platform
