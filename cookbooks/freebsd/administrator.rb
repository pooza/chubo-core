exit unless node.platform == 'freebsd'

# ログインシェルに zsh を割り当てるので、ここで zsh の存在を保証する。zsh cookbook 側にも
# package 'zsh' はあるが、そちらより先に本レシピを回すと wheel ユーザーのシェルが存在せず
# sshd がログインを拒否する。itamae は ENV['USER'] で SSH するため修復経路ごと失われる。
package 'zsh'

node.dig('wheel', 'users').each do |account|
  user account do
    username account
    shell node.dig('zsh', 'bin')
  end

  execute "pw usermod #{account} -G #{node.dig('wheel', 'group')},#{node.dig('sudo', 'group')},#{account}"
end
