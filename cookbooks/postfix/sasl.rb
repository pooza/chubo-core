# Ubuntu の postfix は SASL のプラグインを持たない。無いと relayhost への認証が
# 「no mechanism available」で全部 deferred になる（libsasl2-modules-db だけでは足りない）
package 'libsasl2-modules' if node.platform == 'ubuntu'

directory File.join(node.dig('postfix', 'dir'), 'sasl') do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end

# ⚠⚠ 中身が SendGrid の API キーなので diff を伏せる。伏せないと、キーを差し替えたときに
# 新旧のキーが Controller#report_result から Slack へ平文で投稿される（pooza/chubo2#253）。
template File.join(node.dig('postfix', 'dir'), 'sasl/passwd') do
  source 'templates/passwd.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0640'
  sensitive true
end

execute "postmap #{File.join(node.dig('postfix', 'dir'), 'sasl/passwd')}"
