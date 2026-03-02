accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  execute "chsh -s #{node.dig('zsh', 'bin')} #{account}"
end
