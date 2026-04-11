exit unless node.dig('certbot', 'enable')

email = node.dig('wheel', 'email')
webroot = node.dig('certbot', 'webroot') || '/var/www/html'
node.dig('certbot', 'domains').each do |domain|
  execute "certbot certonly --webroot -n -w #{webroot} -d #{domain} -m #{email} --agree-tos"
end
