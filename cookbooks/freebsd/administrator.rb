exit unless node.platform == 'freebsd'

node.dig('wheel', 'users').each do |account|
  user account do
    username account
    shell node.dig('zsh', 'bin')
  end

  execute "pw usermod #{account} -G #{node.dig('wheel', 'group')},#{node.dig('sudo', 'group')},#{account}"
end
