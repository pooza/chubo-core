exit unless node.platform == 'ubuntu'

execute 'apt update'
execute 'apt autoremove -y'

package 'lv'
package 'wget'
package 'curl'
package 'fzf'
package 'rsync'
package 'unzip'
package 'net-tools'
package 'silversearcher-ag'
package 'build-essential'

# ロケール生成。node.locale だけでなく、各 wheel ユーザーが zshenv で export する
# ユーザー個別 locale（config/user/<user>.yaml の locale、例: deploy=en_US.UTF-8）も
# 生成する。これが無いと当該ユーザーのログインシェル起動時に setlocale が毎回失敗し、
# itamae の出力まで locale 警告で汚染される。
# language-pack-ja は Ubuntu 専用のため実 OS で分岐する。
package 'locales'
package 'language-pack-ja' do
  only_if 'grep -q "^ID=ubuntu" /etc/os-release'
end

locales = [node.locale, *node.dig('wheel', 'users').map {|u| node.dig('users', u, 'locale')}].compact.uniq
locales.each do |loc|
  installed = loc.sub(/\.UTF-8\z/i, '.utf8')
  execute "locale-gen #{loc}" do
    command "grep -qxF '#{loc} UTF-8' /etc/locale.gen || echo '#{loc} UTF-8' >> /etc/locale.gen; locale-gen"
    not_if "locale -a | grep -qFx '#{installed}'"
  end
end
