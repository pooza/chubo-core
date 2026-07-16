exit unless node.dig('nginx', 'enable')

case node.platform
when 'freebsd'
  package 'nginx'
  # not_if が無いと itamae が毎回「変更あり」と報告し、本物の drift と区別できなくなる
  execute 'sysrc nginx_enable="YES"' do
    not_if 'sysrc -n nginx_enable 2>/dev/null | grep -qi "^yes$"'
  end
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
