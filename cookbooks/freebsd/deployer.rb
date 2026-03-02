exit unless node.platform == 'freebsd'
exit unless node.dig('deployer', 'user')

deployer = node.dig('deployer', 'user')

package 'bash'

user deployer do
  username deployer
  home "/home/#{deployer}"
  shell '/usr/local/bin/bash'
  create_home true
end

execute "pw usermod #{deployer} -G #{node.dig('wheel', 'group')},#{node.dig('sudo', 'group')},#{deployer}"

directory "/home/#{deployer}" do
  owner deployer
  group deployer
  mode '0755'
end

directory "/home/#{deployer}/repos" do
  owner deployer
  group deployer
  mode '0755'
end

template "/home/#{deployer}/.bash_profile" do
  source 'templates/bash_profile.erb'
  owner deployer
  group deployer
  mode '0644'
end
