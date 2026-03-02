exit unless node.dig('nginx', 'enable')

case node.platform
when 'freebsd'
  template '/usr/local/etc/rsyslog.d/nginx.conf' do
    source 'templates/rsyslog.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end

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
  template '/etc/rsyslog.d/nginx.conf' do
    source 'templates/rsyslog.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
  end

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
