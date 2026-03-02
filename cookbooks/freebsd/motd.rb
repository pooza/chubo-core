exit unless node.platform == 'freebsd'

execute 'sysrc update_motd=NO'
execute 'sysrc motd_enable=NO'

vars = {
  operating_system: run_command('uname -s').stdout.chomp,
  kernel_version: run_command('freebsd-version -k').stdout.chomp,
  userland_version: run_command('freebsd-version -u').stdout.chomp,
  hardware_platform: run_command('uname -m').stdout.chomp,
}

template '/etc/motd' do
  source 'templates/motd.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
  variables vars
end

template '/var/run/motd' do
  source 'templates/motd.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
  variables vars
end
