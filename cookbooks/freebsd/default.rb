exit unless node.platform == 'freebsd'

execute "sysrc hostname=#{node.nodename}"
execute "hostname #{node.nodename}"

include_recipe 'packages'
include_recipe 'ssh'
include_recipe 'cron'
include_recipe 'make'
include_recipe 'freebsd_update'
include_recipe 'loader'
include_recipe 'sysctl'
include_recipe 'resolver'
include_recipe 'ntpdate'
include_recipe 'motd'
include_recipe 'logging'
include_recipe 'ruby'
include_recipe 'administrator'
include_recipe 'deployer' if node.dig('deployer', 'user')
