exit unless node.dig('nginx', 'enable')

nginx_dir = node.platform == 'freebsd' ? '/usr/local/etc/nginx' : '/etc/nginx'
docroot = node.platform == 'freebsd' ? '/usr/local/www/nginx' : '/var/www/html'
letsencrypt_dir = node.platform == 'freebsd' ? '/usr/local/etc/letsencrypt' : '/etc/letsencrypt'

# ⚠⚠ **無条件 restart はしない。**設定の反映は `nginx -t` を通してからの reload に寄せる。
#
# restart は「設定が壊れていると停止したまま戻らない」のが致命的で、nginx は 1 台に多数の
# vhost が同居するため、1 ドメインの設定ミスがそのノードの全サービスを巻き添えにする。
# 2026-08-09 に noah で実際に起きた（未発行の証明書を指す vhost → `nginx -t` が emerg →
# restart 失敗 → wiki / uptime 4 本が数分停止。pooza/chubo2#163）。
#
# reload なら `nginx -t` が落ちた時点で execute が失敗して itamae が止まり、
# **走っている nginx は古い設定のまま生き残る**。pgbouncer で同じ判断をしている。
# ⚠ nginx の reload は master が設定を読み直して worker を入れ替えるので、worker_processes を
# 含め本 cookbook が書く項目はすべて反映される。バイナリ入れ替え（package 更新）だけは
# restart が要るが、そちらは apt / pkg 側の仕事。
#
# ⚠ **notifies の解決は「通知する側が走る時点」に行われる**ので、この定義は
# 通知するテンプレートより前に無いと `resource is not found` で落ちる（default.rb には置けない）。
execute 'reload nginx' do
  command node.platform == 'freebsd' ? 'nginx -t && service nginx reload' : 'nginx -t && systemctl reload nginx'
  action :nothing
end

template "#{nginx_dir}/nginx.conf" do
  source 'templates/nginx.conf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
  notifies :run, 'execute[reload nginx]'
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
  template "#{nginx_dir}/servers/#{node.nodename}.conf" do
    source 'templates/self.conf.erb'
    owner 'root'
    group node.dig('wheel', 'group')
    mode '0644'
    variables(nodename: node.nodename, docroot: docroot, letsencrypt_dir: letsencrypt_dir)
    only_if "test -f #{letsencrypt_dir}/live/#{node.nodename}/fullchain.pem"
    notifies :run, 'execute[reload nginx]'
  end
end

# 背後に自ノードのアプリを持たない vhost（＝他ノードへ中継するだけのリバースプロキシ）は、
# 露出すべきアプリが無いので所有者になれる cookbook が存在しない。それは nginx の設定
# そのものなので、node yaml の宣言からここで生成する。自ノードのアプリを露出する vhost は
# host/port を知っているアプリ側の cookbook が持つこと（wikijs, uptime-kuma 等）。
# backend の代わりに redirect を書くと、中継せず 302 を返すだけの vhost になる
# （別ホストの status ページや外部フォームへの入口など）。証明書と access ログの
# 扱いは中継用と同じなので、同じ proxies に並べる。
#
# ⚠⚠ **証明書がまだ無いドメインの 443 ブロックを出してはいけない。**
# `ssl_certificate` が存在しないファイルを指すと `nginx -t` が emerg で落ち、
# **そのノードの nginx が丸ごと起動できなくなる**（同居している他の vhost が巻き添え）。
# 2026-08-09 に noah で実際に踏み、wiki / uptime 4 本が数分停止した（pooza/chubo2#163）。
# self_vhost が only_if で証明書の存在を見ているのと同じ理由。
#
# 未発行のときは :80 だけ出す。ACME の HTTP-01 は :80 で検証するので、この vhost が
# 先に立っていないと certbot 側も発行できない（鶏と卵になる）。証明書が出れば
# 次の適用で 443 が生える。発行そのものは certbot cookbook が受け持つ。
(node.dig('nginx', 'proxies') || []).each do |proxy|
  tls = run_command("test -f #{letsencrypt_dir}/live/#{proxy['host']}/fullchain.pem", error: false)
    .exit_status.zero?

  template "#{nginx_dir}/servers/#{proxy['host']}.conf" do
    source 'templates/proxy.conf.erb'
    owner 'root'
    group node.dig('wheel', 'group')
    mode '0644'
    variables(proxy: proxy, tls: tls, docroot: docroot, letsencrypt_dir: letsencrypt_dir)
    notifies :run, 'execute[reload nginx]'
  end
end
