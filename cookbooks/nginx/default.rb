exit unless node.dig('nginx', 'enable')

include_recipe 'package'
include_recipe 'config'
include_recipe 'logging'

if node.platform == 'freebsd'
  # nginx_enable の設定は package.rb が持つ（ここに書くと二重実行になる）
  service 'nginx' do
    action [:start, :restart]
  end
else
  service 'nginx' do
    action [:enable, :restart]
  end
end
