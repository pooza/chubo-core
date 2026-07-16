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

# 背後に自ノードのアプリを持たない vhost（＝他ノードへ中継するだけのリバースプロキシ）は、
# 露出すべきアプリが無いので所有者になれる cookbook が存在しない。それは nginx の設定
# そのものなので、node yaml の宣言からここで生成する。自ノードのアプリを露出する vhost は
# host/port を知っているアプリ側の cookbook が持つこと（wikijs, uptime-kuma 等）。
(node.dig('nginx', 'proxies') || []).each do |proxy|
  template "#{nginx_dir}/servers/#{proxy['host']}.conf" do
    source 'templates/proxy.conf.erb'
    owner 'root'
    group node.dig('wheel', 'group')
    mode '0644'
    variables(proxy: proxy)
  end
end
