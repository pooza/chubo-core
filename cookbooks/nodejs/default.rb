exit unless node.dig('nodejs', 'enable')

include_recipe node.platform
