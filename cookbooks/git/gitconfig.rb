# ~/.gitconfig はこのレシピが丸ごと書く。台ごとの設定（gh auth setup-git の credential helper など）は
# ~/.gitconfig.local に置く（末尾の [include] で読む）。⚠ ~/.gitconfig に足したものは次に流したとき消える。
accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  # config/user/<名前>.yaml が無いユーザーは [user] を書かない（以前は nil で落ちた）
  user = node.dig('users', account) || {}

  template File.join(node['user'].dig(account, 'directory'), '.gitconfig') do
    source 'templates/gitconfig.erb'
    owner account
    group account == 'root' ? node.dig('root', 'group') : account
    mode '0644'
    variables(user:)
  end
end
