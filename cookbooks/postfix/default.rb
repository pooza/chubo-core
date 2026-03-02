package node.dig('postfix', 'package')

include_recipe 'sysrc' if node.platform == 'freebsd'
include_recipe 'mailerconf' if node.platform == 'freebsd'
include_recipe 'maincf'
include_recipe 'aliases'
include_recipe 'sasl'

if node.platform == 'freebsd'
  service 'postfix' do
    action [:start, :restart]
  end
else
  service 'postfix' do
    action [:enable, :restart]
  end
end
