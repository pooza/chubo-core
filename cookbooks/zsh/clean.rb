accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  [
    '.cshrc',
    '.login',
    '.login_conf',
    '.mail_aliases',
    '.mailrc',
    '.profile',
    '.rhosts',
    '.shrc',
    '.k5login',
    '.lesshst',
  ].freeze.each do |name|
    file File.join(node['user'].dig(account, 'directory'), name) do
      action :delete
    end
  end
end
