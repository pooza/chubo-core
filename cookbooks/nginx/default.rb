exit unless node.dig('nginx', 'enable')

include_recipe 'package'
include_recipe 'config'
include_recipe 'logging'
# ⚠⚠ **取り込む先が自分と違う条件で `exit` するなら、取り込む側で条件を付ける。**
# itamae は取り込んだレシピの `exit` でプロセスごと終わり、**それより前に並べたリソースも含めて
# 何も適用しないまま正常終了する**（出力も出ない）。条件に合わないノードでは、このレシピ全体が
# 黙って空振りになっていた（pooza/chubo2#164 の dev29 構築で発覚）。
surge = node.dig('nginx', 'surge', 'enable') && node.dig('nginx', 'surge', 'kuma_push_token')
include_recipe 'surge' if surge && node.platform == 'freebsd'

# ⚠ **restart はしない。**設定の反映は config.rb の `execute[reload nginx]`（notifies）が持つ。
# ここは「落ちていれば起動する」だけ。起動時に新しい設定が読まれるので、
# 起動した回の reload は空振りでよい。理由は config.rb の当該箇所のコメント。
if node.platform == 'freebsd'
  # nginx_enable の設定は package.rb が持つ（ここに書くと二重実行になる）
  service 'nginx' do
    action [:start]
  end
else
  service 'nginx' do
    action [:enable, :start]
  end
end
