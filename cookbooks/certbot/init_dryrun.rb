exit unless node.dig('certbot', 'enable')

email = node.dig('wheel', 'email')
node.dig('certbot', 'domains').each do |domain|
  execute "certbot certonly --webroot -n -w /var/www/html -d #{domain} -m #{email} --agree-tos --dry-run"
end
