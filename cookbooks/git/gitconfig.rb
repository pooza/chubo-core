accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  user = node.dig('users', account)

  template File.join(node['user'].dig(account, 'directory'), '.gitconfig') do
    source 'templates/gitconfig.erb'
    owner account
    group account == 'root' ? node.dig('root', 'group') : account
    mode '0644'
    variables(user:)
  end
end
