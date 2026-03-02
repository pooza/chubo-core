exit unless node.platform == 'ubuntu'

node.dig('wheel', 'users').each do |account|
  user account do
    username account
    shell node.dig('zsh', 'bin')
  end

  execute "usermod -aG #{node.dig('wheel', 'group')} #{account}"
  execute "usermod -aG #{node.dig('sudo', 'group')} #{account}"

  directory File.join(node['user'].dig(account, 'directory'), '.config') do
    owner account
    group account
    mode '0700'
  end
end
