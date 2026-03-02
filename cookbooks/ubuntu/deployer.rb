exit unless node.platform == 'ubuntu'
exit unless node.dig('deployer', 'user')

directory "/home/#{node.dig('deployer', 'user')}" do
  owner node.dig('deployer', 'user')
  group node.dig('deployer', 'user')
  mode '0755'
end

directory "/home/#{node.dig('deployer', 'user')}/repos" do
  owner node.dig('deployer', 'user')
  group node.dig('deployer', 'user')
  mode '0755'
end
