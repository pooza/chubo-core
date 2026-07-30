exit unless node.dig('unbound', 'enable')
exit unless node.platform == 'ubuntu'

package 'unbound'

# Ubuntu の unbound.conf は conf.d/*.conf を include-toplevel するので、
# パッケージ本体の設定には手を触れず drop-in だけを置く。
# （root トラストアンカー等の既定を上書きしないため。redis/ubuntu.rb と同じ方針）
template '/etc/unbound/unbound.conf.d/chubo.conf' do
  source 'templates/unbound.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  notifies :restart, 'service[unbound]'
end

# 壊れた設定のまま restart すると名前解決が止まる。反映前に必ず検証する。
execute 'unbound-checkconf' do
  command 'unbound-checkconf'
end

service 'unbound' do
  action [:enable, :start]
end
