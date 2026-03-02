exit unless node.dig('nginx', 'enable')

case node.platform
when 'freebsd'
  package 'nginx'
  execute 'sysrc nginx_enable="YES"'
when 'ubuntu'
  service 'apache2' do
    action [:disable, :stop]
  end

  package 'apache2' do
    action :remove
  end

  package 'nginx'
  package 'apache2-utils'
end
