template File.join(node.dig('postfix', 'dir'), 'aliases') do
  source 'templates/aliases.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end

execute "postmap #{File.join(node.dig('postfix', 'dir'), 'aliases')}"
