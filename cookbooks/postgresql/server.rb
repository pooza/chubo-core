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

  template '/usr/local/etc/monit.d/postgres' do
    source 'templates/monit.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0644'
    only_if 'test -d /usr/local/etc/monit.d'
  end

  execute 'monit reload' do
    only_if 'service monit status'
  end
when 'ubuntu'
  # Ubuntu ネイティブ postgresql（26.04 は PG18）。PGDG は resolute 未対応の恐れがあり、
  # ステージングはインフラ忠実性が対象外のため native を採る。apt がクラスタ作成＋
  # systemd 起動まで行うので initdb 不要。
  # ⚠ postgresql-contrib は入れない。26.04 には実体が無く（apt の候補が無い仮想パッケージ）、
  # apt は postgresql-18 で満たして正常終了するが dpkg 上は un のままなので、
  # itamae が毎回「未インストール」と報告してドリフト確認（pooza/chubo2#121）を濁す。
  # contrib のエクステンション（pg_trgm / pgcrypto / hstore / pg_stat_statements）は
  # postgresql-18 に同梱されていることを実機で確認済み。
  package 'postgresql'

  service 'postgresql' do
    action [:enable, :start]
  end

  # ⚠ pg_hba.conf はこれまでどのレシピも管理しておらず、sweep も dev27 も手作業だった
  # （infra-note の「local と 127.0.0.1/::1 を trust」は状態の記述で、宣言ではなかった）。
  # 宣言のあるノードだけ管理下に置く（pooza/chubo2#35）。
  # ⚠ パスに版が入るので postgresql.version の宣言が要る。Ubuntu は native を入れるので、
  # platform 既定（PGDG 用）ではなく実際に入る版を node yaml に書くこと。
  if (hba = node.dig('postgresql', 'server', 'hba'))
    # ⚠ notifies の解決は「通知する側が走る時点」なので、template より前に置く。
    execute 'systemctl reload postgresql' do
      action :nothing
    end

    template "/etc/postgresql/#{node.dig('postgresql', 'version')}/main/pg_hba.conf" do
      source 'templates/pg_hba.conf.erb'
      owner 'postgres'
      group 'postgres'
      mode '0640'
      variables(hba:)
      notifies :run, 'execute[systemctl reload postgresql]'
    end
  end
end
