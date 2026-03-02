exit unless node.dig('postgresql', 'server', 'enable')
exit unless node.platform == 'freebsd'

version = node.dig('postgresql', 'version')
data_dir = "/var/db/postgres/data#{version}"

package "postgresql#{version}-server"
package "postgresql#{version}-client"

execute 'sysrc postgresql_enable="YES"'
execute "sysrc postgresql_data=#{data_dir}"

execute "initdb for postgresql#{version}" do
  command "/usr/local/bin/initdb -D #{data_dir} -E UTF8 --locale=C"
  user 'postgres'
  not_if "test -f #{data_dir}/PG_VERSION"
end

service 'postgresql' do
  action [:start]
end

template '/usr/local/etc/rsyslog.d/postgresql.conf' do
  source 'templates/rsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

template '/usr/local/etc/newsyslog.conf.d/postgresql.conf' do
  source 'templates/newsyslog.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'sysrc rsyslogd_enable="YES"'
service 'rsyslogd' do
  action [:start, :restart]
end
