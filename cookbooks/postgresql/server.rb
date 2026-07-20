exit unless node.dig('postgresql', 'server', 'enable')

case node.platform
when 'freebsd'
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

  # node の postgresql.tuning を ALTER SYSTEM で適用する。
  # 本番 3 台は同じ値が手作業で入っていたが、レシピが参照していなかったため
  # 新規構築機だけが既定値のまま立ち上がっていた（pooza/chubo2#76）。
  # ALTER SYSTEM は postgresql.auto.conf へ `key = 'value'` の形で書くので、
  # そのまま冪等判定に使える。shared_buffers 等は反映に再起動が要る。
  (node.dig('postgresql', 'tuning') || {}).each do |key, value|
    execute "alter system set #{key}" do
      command %(/usr/local/bin/psql -c "ALTER SYSTEM SET #{key} = '#{value}'")
      user 'postgres'
      not_if %(grep -qF "#{key} = '#{value}'" #{data_dir}/postgresql.auto.conf)
      notifies :restart, 'service[postgresql]'
    end
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
when 'ubuntu'
  # Ubuntu ネイティブ postgresql（26.04 は PG18）。PGDG は resolute 未対応の恐れがあり、
  # ステージングはインフラ忠実性が対象外のため native を採る。apt がクラスタ作成＋
  # systemd 起動まで行うので initdb 不要。
  package 'postgresql'
  package 'postgresql-contrib'

  service 'postgresql' do
    action [:enable, :start]
  end
end
