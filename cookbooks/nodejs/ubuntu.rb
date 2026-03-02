exit unless node.dig('nodejs', 'enable')
exit unless node.platform == 'ubuntu'

path = File.join('/home', node.dig('deployer', 'user'), 'nodesource_setup.sh')

execute "curl -sL #{node.dig('nodejs', 'src')} -o #{path}"
execute "bash #{path}"

package 'nodejs' do
  action :remove
end
package 'nodejs'
execute 'corepack enable'

file path do
  action :delete
end
