accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  user = node.dig('users', account)

  [:zshenv, :zlogout, :zshrc].freeze.each do |file|
    template File.join(node['user'].dig(account, 'directory'), ".#{file}") do
      source "templates/#{file}.erb"
      owner account
      group account == 'root' ? node.dig('root', 'group') : account
      mode '0644'
      variables(user:)
    end
  end
end
