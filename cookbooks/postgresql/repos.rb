exit if !node.dig('postgresql', 'server', 'enable') && !node.dig('postgresql', 'client', 'enable')

directory '/etc/apt/sources.list.d' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end
# apt のサードパーティ suite 名（codename）。⚠⚠ **yaml の `release` より実機の `/etc/os-release` を優先する**
# （pooza/chubo-core#20）。platform yaml に 1 つだけ書くと、版の違う機（例: 26.04 の中の 24.04）が
# **黙って一世代前の suite を掴み続ける**。明示の `postgresql.src.suite` があればそれが最優先
# （上流がまだ新しい codename を配っていないときの逃げ道）。`release` は取れなかったときの予備。
os_codename = run_command('. /etc/os-release && echo "$VERSION_CODENAME"', error: false).stdout.strip
postgresql_suite = node.dig('postgresql', 'src', 'suite') || (os_codename.empty? ? node.release : os_codename)

template '/etc/apt/sources.list.d/postgresql.list' do
  source 'templates/postgresql.list.erb'
  variables(suite: postgresql_suite)
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute 'wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -' do
  not_if 'apt-key list | grep -q "PostgreSQL Debian Repository"'
end
