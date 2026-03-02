exit unless node.dig('nginx', 'enable')

nginx_dir = node.platform == 'freebsd' ? '/usr/local/etc/nginx' : '/etc/nginx'

template "#{nginx_dir}/nginx.conf" do
  source 'templates/nginx.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

directory "#{nginx_dir}/servers" do
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0775'
end
