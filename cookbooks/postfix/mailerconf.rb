exit unless node.platform == 'freebsd'

file '/etc/mail/mailer.conf' do
  action :delete
end
link '/etc/mail/mailer.conf' do
  to '/usr/local/share/postfix/mailer.conf.postfix'
end
