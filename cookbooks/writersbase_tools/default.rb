require 'json'
require 'yaml'

exit unless node.dig('writersbase_tools', 'enable')

user = node.dig('writersbase_tools', 'user') || node.dig('deployer', 'user')
path = node.dig('writersbase_tools', 'path') || "/home/#{user}/repos/writersbase-tools"
package_name = 'writersbase-tools'

# Itamae::Mash のまま to_yaml すると Ruby クラスタグが出力されるため、
# JSON 往復でプレーンな Hash/Array に変換してから YAML 化する
config_data = node.dig('writersbase_tools', 'config') || {}
plain_config = JSON.parse(config_data.to_json)
local_yaml = YAML.dump(plain_config).sub(/\A---\n?/, '')

case node.platform
when 'freebsd'
  config_dir = "/usr/local/etc/#{package_name}"
  rsyslog_conf = "/usr/local/etc/rsyslog.d/#{package_name}.conf"
  newsyslog_conf = "/usr/local/etc/newsyslog.conf.d/#{package_name}.conf"
  rsyslog_service = 'rsyslogd'
  native_packages = ['mysql80-client']
# Ubuntu 対応時は以下のようにブランチを追加する
# when 'ubuntu'
#   config_dir = "/etc/#{package_name}"
#   rsyslog_conf = "/etc/rsyslog.d/#{package_name}.conf"
#   logrotate_conf = "/etc/logrotate.d/#{package_name}"
#   rsyslog_service = 'rsyslog'
#   native_packages = ['default-libmysqlclient-dev']
else
  exit
end

root_group = node.dig('root', 'group')

# writersbase-tools の Gemfile が mysql2 と pg を無条件に要求するため、
# MySQL クライアントライブラリを入れておく（実際に MySQL を使わなくても必要）
native_packages.each do |pkg|
  package pkg
end

directory config_dir do
  owner 'root'
  group root_group
  mode '0755'
end

# Ginseng::Config は /usr/local/etc/<package>/ を直接読むため、
# リポジトリ側の config/local.yaml シンボリックリンクは作らない方針
template File.join(config_dir, 'local.yaml') do
  source 'templates/local.yaml.erb'
  owner user
  group user
  mode '0644'
  variables(content: local_yaml)
end

# 過去に設置されていた冗長なシンボリックリンクがあれば削除
execute "remove legacy #{package_name} config symlink" do
  command "rm -f #{path}/config/local.yaml"
  only_if "test -L #{path}/config/local.yaml"
end

template rsyslog_conf do
  source 'templates/rsyslog.erb'
  owner 'root'
  group root_group
  mode '0644'
end

case node.platform
when 'freebsd'
  template newsyslog_conf do
    source 'templates/newsyslog.erb'
    owner 'root'
    group root_group
    mode '0644'
  end

  execute 'sysrc rsyslogd_enable="YES"'
end

service rsyslog_service do
  action [:start, :restart]
end

# rclone セットアップ（現状 google_drive_backup のみが依存）
# トークン等の機密は chubo2 の config/local.yaml に置く前提
if node.dig('writersbase_tools', 'rclone', 'enable')
  package 'rclone'

  directory '/root/.config/rclone' do
    owner 'root'
    group root_group
    mode '0700'
  end

  rclone_remotes_data = node.dig('writersbase_tools', 'rclone', 'remotes') || {}
  rclone_remotes = JSON.parse(rclone_remotes_data.to_json)

  template '/root/.config/rclone/rclone.conf' do
    source 'templates/rclone.conf.erb'
    owner 'root'
    group root_group
    mode '0600'
    variables(remotes: rclone_remotes)
  end
end

# periodic (cron) スクリプト配置: writersbase-tools 側の rake install に委譲
# FreeBSD: /usr/local/etc/periodic/{hourly,daily,weekly,monthly}/
# Ubuntu: /etc/cron.{hourly,daily,weekly,monthly}/
#
# 前提: root から system ruby + bundle が使える状態
#  (FreeBSD の場合 pkg の ruby + rubygem-bundler)
if node.dig('writersbase_tools', 'install_periodic')
  execute "#{package_name} bundle install" do
    command 'bundle install --quiet'
    cwd path
    user 'root'
    only_if "test -f #{path}/Gemfile"
  end

  # bundle exec を挟まないと、Gemfile.lock が固定する rake ではなく
  # default gem の rake が先に activate されて Gem::LoadError になる
  execute "#{package_name} rake install" do
    command 'bundle exec rake install'
    cwd path
    user 'root'
    only_if "test -f #{path}/Rakefile"
  end
end
