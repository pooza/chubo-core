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
