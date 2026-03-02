template File.join(node.dig('postfix', 'dir'), 'main.cf') do
  source 'templates/main.cf.erb'
  owner 'root'
  group node.dig('root', 'group')
  mode '0644'
end
