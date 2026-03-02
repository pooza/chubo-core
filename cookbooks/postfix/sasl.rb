directory File.join(node.dig('postfix', 'dir'), 'sasl') do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end

template File.join(node.dig('postfix', 'dir'), 'sasl/passwd') do
  source 'templates/passwd.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0640'
end

execute "postmap #{File.join(node.dig('postfix', 'dir'), 'sasl/passwd')}"
