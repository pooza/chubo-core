accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  directory File.join(node['user'].dig(account, 'directory'), '.vim') do
    owner account
    group account == 'root' ? node.dig('root', 'group') : account
    mode '0755'
  end

  directory File.join(node['user'].dig(account, 'directory'), '.vim/indent') do
    owner account
    group account == 'root' ? node.dig('root', 'group') : account
    mode '0755'
  end

  [:ruby, :php, :yaml, :javascript, :json].freeze.each do |filetype|
    template File.join(node['user'].dig(account, 'directory'), ".vim/indent/#{filetype}.vim") do
      source "templates/indent/#{filetype}.vim.erb"
      owner account
      group account == 'root' ? node.dig('root', 'group') : account
      mode '0644'
    end
  end
end
