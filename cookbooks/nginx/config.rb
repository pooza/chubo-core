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

# 自ノードの FQDN そのものを HTTPS で終端する vhost。アプリを露出しないので
# アプリ側の cookbook が持てず、中継でもないので proxies にも乗らない。
# 用途は「本番ドメインを切り替える前に、その機体で HTTPS の経路（ACME の検証と
# 更新まで）が通ることを確認する」こと。証明書が無い状態でこれを置くと nginx が
# 起動しなくなるため、証明書が存在するときだけ生成する。
if node.dig('nginx', 'self_vhost')
  docroot = node.platform == 'freebsd' ? '/usr/local/www/nginx' : '/var/www/html'
  letsencrypt_dir = node.platform == 'freebsd' ? '/usr/local/etc/letsencrypt' : '/etc/letsencrypt'

  template "#{nginx_dir}/servers/#{node.nodename}.conf" do
    source 'templates/self.conf.erb'
    owner 'root'
    group node.dig('wheel', 'group')
    mode '0644'
    variables(nodename: node.nodename, docroot: docroot, letsencrypt_dir: letsencrypt_dir)
    only_if "test -f #{letsencrypt_dir}/live/#{node.nodename}/fullchain.pem"
  end
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
