exit unless node.dig('wikijs', 'enable')

dir = node.dig('wikijs', 'path')
dir.gsub!('__USER__', node.dig('deployer', 'user'))

git dir do
  repository node.dig('wikijs', 'repos')
  user node.dig('deployer', 'user')
end

execute 'docker compose up -d' do
  cwd dir
end
