package 'gh'

# gh のログイン（~/.config/gh/hosts.yml）を扱う。
#
# - users.<名前>.gh に token / user がある → このレシピが hosts.yml を書く
# - users.<名前>.gh が false → hosts.yml を消す（ログインを置かせない台で明示する）
# - **宣言が無い → 触らない。**
#
# ⚠⚠ 以前は宣言が無いと hosts.yml を消していた。gh auth login で入れたログインが
# レシピを流すたびに消え、トークンは hosts.yml にしか無いので、git の https の push と gh が
# 止まる（2026-11-15。新しい作業機に git レシピを流して、2 ユーザーのログインが消えた）。
accounts = node.dig('wheel', 'users').push('root').to_set
accounts.each do |account|
  user = node.dig('users', account) || {}
  dir = File.join(node['user'].dig(account, 'directory'), '.config/gh')

  if user['gh']
    directory dir do
      owner account
      group account == 'root' ? node.dig('root', 'group') : account
      mode '0700'
    end
    template File.join(dir, 'hosts.yml') do
      source 'templates/host.yml.erb'
      owner account
      group account == 'root' ? node.dig('root', 'group') : account
      mode '0600'
      # ⚠ 中身が GitHub の oauth_token なので diff を伏せる（Slack へ平文で流れる・pooza/chubo2#253）
      sensitive true
      variables(user:)
    end
  elsif user['gh'] == false
    file File.join(dir, 'hosts.yml') do
      action :delete
    end
    directory dir do
      action :delete
    end
  end
end
