exit unless node.dig('certbot', 'enable')

package 'certbot'

template '/etc/cron.weekly/certbot' do
  source 'templates/certbot.sh.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end

execute 'certbot renew'
