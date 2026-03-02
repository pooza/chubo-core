exit unless node.dig('nginx', 'enable')

include_recipe 'package'
include_recipe 'config'
include_recipe 'logging'

if node.platform == 'freebsd'
  execute 'sysrc nginx_enable="YES"'
  service 'nginx' do
    action [:start, :restart]
  end
else
  service 'nginx' do
    action [:enable, :restart]
  end
end
