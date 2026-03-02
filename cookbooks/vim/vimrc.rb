accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  template File.join(node['user'].dig(account, 'directory'), '.vimrc') do
    source 'templates/vimrc.erb'
    owner account
    group account == 'root' ? node.dig('root', 'group') : account
    mode '0644'
  end
end
