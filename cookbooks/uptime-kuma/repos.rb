exit unless node.dig('uptime-kuma', 'enable')

dir = node.dig('uptime-kuma', 'path')
dir.gsub!('__USER__', node.dig('deployer', 'user'))

git dir do
  repository node.dig('uptime-kuma', 'repos')
  user node.dig('deployer', 'user')
end

execute 'docker compose up -d' do
  cwd dir
end
