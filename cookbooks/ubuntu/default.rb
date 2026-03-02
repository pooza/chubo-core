exit unless node.platform == 'ubuntu'

execute "hostnamectl set-hostname #{node.nodename}"
execute "timedatectl set-timezone #{node.timezone}"

include_recipe 'packages'
include_recipe 'ssh'
include_recipe 'cron'
include_recipe 'logging'
include_recipe 'ruby'
include_recipe 'administrator'
include_recipe 'deployer' if node.dig('deployer', 'user')
