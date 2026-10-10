exit unless node.platform == 'ubuntu'

execute "hostnamectl set-hostname #{node.nodename}"
execute "timedatectl set-timezone #{node.timezone}"

include_recipe 'packages'
# ⚠⚠ **取り込む先が自分と違う条件で `exit` するなら、取り込む側で条件を付ける。**
# itamae は取り込んだレシピの `exit` でプロセスごと終わり、**それより前に並べたリソースも含めて
# 何も適用しないまま正常終了する**（出力も出ない）。条件に合わないノードでは、このレシピ全体が
# 黙って空振りになっていた（pooza/chubo2#164 の dev29 構築で発覚）。
include_recipe 'unattended_upgrades' if node['unattended_upgrades']
needrestart = node.dig('needrestart', 'override_rc')
include_recipe 'needrestart' unless needrestart.nil? || needrestart.empty?
include_recipe 'ssh'
include_recipe 'cron'
include_recipe 'logging'
include_recipe 'ruby'
include_recipe 'administrator'
include_recipe 'deployer' if node.dig('deployer', 'user')
