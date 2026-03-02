package 'gh'

accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  user = node.dig('users', account)

  if user['gh']
    directory File.join(node['user'].dig(account, 'directory'), '.config/gh') do
      owner account
      group account == 'root' ? node.dig('root', 'group') : account
      mode '0700'
    end
    template File.join(node['user'].dig(account, 'directory'), '.config/gh/hosts.yml') do
      source 'templates/host.yml.erb'
      owner account
      group account == 'root' ? node.dig('root', 'group') : account
      mode '0600'
      variables(user:)
    end
  else
    file File.join(node['user'].dig(account, 'directory'), '.config/gh/hosts.yml') do
      action :delete
    end
    directory File.join(node['user'].dig(account, 'directory'), '.config/gh') do
      action :delete
    end
  end
end
