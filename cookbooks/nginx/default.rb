exit unless node.dig('nginx', 'enable')

include_recipe 'package'
include_recipe 'config'
include_recipe 'logging'

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
