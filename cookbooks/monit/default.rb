exit unless node.dig('monit', 'enable')

include_recipe node.platform
