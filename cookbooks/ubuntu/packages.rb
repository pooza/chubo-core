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

# 日本語ロケール。language-pack-ja は Ubuntu 専用のため実 OS で分岐し、
# ロケール生成自体は Ubuntu / Debian 共通の locales + locale-gen で行う。
if node.locale == 'ja_JP.UTF-8'
  package 'language-pack-ja' do
    only_if 'grep -q "^ID=ubuntu" /etc/os-release'
  end
  package 'locales'
  execute 'locale-gen ja_JP.UTF-8' do
    not_if 'locale -a | grep -qi "^ja_JP.utf8$"'
  end
end
