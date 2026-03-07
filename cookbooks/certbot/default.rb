exit unless node.dig('certbot', 'enable')

deploy_hook = node.dig('certbot', 'deploy_hook') || 'service nginx onereload'
certbot_package = node.dig('certbot', 'package') || 'certbot'

package certbot_package

case node.platform
when 'freebsd'
  execute 'enable weekly certbot' do
    command 'sysrc -f /etc/periodic.conf weekly_certbot_enable="YES"'
    not_if 'grep -q \'weekly_certbot_enable="YES"\' /etc/periodic.conf'
  end

  execute 'set certbot deploy hook' do
    command "sysrc -f /etc/periodic.conf weekly_certbot_deploy_hook=\"#{deploy_hook}\""
  end
when 'ubuntu'
  template '/etc/cron.weekly/certbot' do
    source 'templates/certbot.sh.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0755'
  end

  execute 'certbot renew'
end
