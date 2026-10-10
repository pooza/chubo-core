exit unless node.platform == 'freebsd'

execute "sysrc hostname=#{node.nodename}"
execute "hostname #{node.nodename}"

include_recipe 'timezone'
include_recipe 'packages'
include_recipe 'ssh'
include_recipe 'cron'
include_recipe 'make'
include_recipe 'freebsd_update'
include_recipe 'loader'
include_recipe 'sysctl'
# ⚠⚠ **取り込む先が自分と違う条件で `exit` するなら、取り込む側で条件を付ける。**
# itamae は取り込んだレシピの `exit` でプロセスごと終わり、**それより前に並べたリソースも含めて
# 何も適用しないまま正常終了する**（出力も出ない）。条件に合わないノードでは、このレシピ全体が
# 黙って空振りになっていた（pooza/chubo2#164 の dev29 構築で発覚）。
include_recipe 'network' if node['network']
include_recipe 'resolver'
include_recipe 'ntpdate'
include_recipe 'motd'
include_recipe 'logging'
include_recipe 'ruby' if node.dig('ruby', 'system', 'version')
include_recipe 'administrator'
include_recipe 'deployer' if node.dig('deployer', 'user')
