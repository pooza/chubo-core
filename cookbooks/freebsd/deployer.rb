exit unless node.platform == 'freebsd'
exit unless node.dig('deployer', 'user')

deployer = node.dig('deployer', 'user')

# ⚠ `.bash_profile` を配るので bash 自体は要る（`bash -lc` でデプロイを叩くため）。
# ログインシェルに使うかどうかとは別の話。
package 'bash'

# ⚠⚠ **ログインシェルは `zsh.bin` を見る。**ここが `/usr/local/bin/bash` を
# ハードコードしていたため、`administrator.rb`（wheel.users を `zsh.bin` にする）と
# **同じユーザーの同じ属性を取り合っていた**。deployer が wheel.users にも入っている
# 構成（mastodon / deploy）では、どちらのレシピを後に流すかで結果が変わる。
#
# 🔴 #121 の全ノード dry-run で、**FreeBSD 10 台すべてが zsh→bash の差分を出した**
# （実機は全台 zsh ＝ administrator 側が勝った状態）。宣言を一本化して綱引きを止める。
user deployer do
  username deployer
  home "/home/#{deployer}"
  shell node.dig('zsh', 'bin')
  create_home true
end

execute "pw usermod #{deployer} -G #{node.dig('wheel', 'group')},#{node.dig('sudo', 'group')},#{deployer}"

directory "/home/#{deployer}" do
  owner deployer
  group deployer
  mode '0755'
end

directory "/home/#{deployer}/repos" do
  owner deployer
  group deployer
  mode '0755'
end

template "/home/#{deployer}/.bash_profile" do
  source 'templates/bash_profile.erb'
  owner deployer
  group deployer
  mode '0644'
end
