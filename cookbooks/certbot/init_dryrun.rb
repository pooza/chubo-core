exit unless node.dig('certbot', 'enable')

email = node.dig('wheel', 'email')
# ⚠ **既定を platform で分ける。**FreeBSD に `/var/www/html` は無いので、宣言を省いた
# FreeBSD ノードでは初回発行がそのまま落ちる。`default.rb` は分けているのに、こちらだけ
# 分かれていなかった（pooza/chubo2#216 の同格ノード差分で発覚。shallu だけ webroot の
# 宣言が無く、gomander / zugoga は明示していたので誰も踏んでいなかった）。
webroot = node.dig('certbot', 'webroot') ||
  (node.platform == 'freebsd' ? '/usr/local/www/nginx' : '/var/www/html')
node.dig('certbot', 'domains').each do |domain|
  execute "certbot certonly --webroot -n -w #{webroot} -d #{domain} -m #{email} --agree-tos --dry-run"
end
