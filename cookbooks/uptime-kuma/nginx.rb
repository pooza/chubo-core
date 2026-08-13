exit unless node.dig('uptime-kuma', 'enable')

# ⚠ 無条件 restart はしない（pooza/chubo2#163）。設定が壊れていると nginx が停止した
# まま戻らず、1 vhost のミスでそのノードの全サービスを巻き添えにする。`nginx -t` を
# 通してからの reload なら、失敗しても走っている nginx は古い設定のまま生き残る。
# 理由は nginx/config.rb の当該箇所のコメント。
#
# ⚠ chubo-core の nginx cookbook が持つ execute[reload nginx] には notifies できない。
# アプリ単体で流すとき（例: --recipes=uptime-kuma）は nginx cookbook が走っておらず、
# その resource が存在しないため。各 cookbook が自前で持つ。
execute 'reload nginx' do
  command node.platform == 'freebsd' ? 'nginx -t && service nginx reload' : 'nginx -t && systemctl reload nginx'
  action :nothing
end

template "/etc/nginx/servers/#{node.dig('uptime-kuma', 'host')}.conf" do
  source 'templates/nginx.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0664'
  notifies :run, 'execute[reload nginx]'
end

service 'rsyslog' do
  action :restart
end
