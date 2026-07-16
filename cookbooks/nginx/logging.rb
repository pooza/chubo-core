exit unless node.dig('nginx', 'enable')

rsyslog_dir = node.platform == 'freebsd' ? '/usr/local/etc/rsyslog.d' : '/etc/rsyslog.d'

template "#{rsyslog_dir}/nginx.conf" do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

# vhost を置いた者が、その access ログを回収する。config.rb が生成する proxy vhost の
# tag はこの cookbook が所有しているので、対応する per-tag ルールもここで出す。
# 自分が書いていない tag を拾う catch-all（:programname, startswith, "nginx_" 等）は
# 置かないこと。tag を所有する他の cookbook（wikijs, uptime-kuma, matrix 等）のルールと
# 両方が発火し、二重書き込みになる。
(node.dig('nginx', 'proxies') || []).each do |proxy|
  template "#{rsyslog_dir}/#{proxy['tag']}.conf" do
    source 'templates/rsyslog_proxy.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
    variables(proxy: proxy)
  end
end

case node.platform
when 'freebsd'
  template '/usr/local/etc/newsyslog.conf.d/nginx.conf' do
    source 'templates/newsyslog.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end

  execute 'sysrc rsyslogd_enable="YES"'
  service 'rsyslogd' do
    action [:start, :restart]
  end
when 'ubuntu'
  [
    '/var/log/nginx/error.log',
    '/var/log/nginx/access.log',
  ].each do |path|
    file path do
      action :delete
    end
  end

  service 'rsyslog' do
    action :restart
  end

  template '/etc/logrotate.d/nginx' do
    source 'templates/logrotate.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end
end
