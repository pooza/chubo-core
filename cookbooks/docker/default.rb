exit unless node.dig('docker', 'enable')

package 'docker-ce'
package 'docker-ce-cli'
package 'containerd.io'
package 'docker-compose-plugin'

link '/usr/local/bin/docker-compose' do
  to '/usr/libexec/docker/cli-plugins/docker-compose'
  force true
end
