exit unless node.platform == 'freebsd'

# ⚠ 以前は `file ... action :delete` → `link` の 2 段で、流すたびに既にある symlink を消して張り直していた
# （dry-run に毎回 mailer.conf の削除が出る・消えている間の sendmail は行き先を失う）。
# base の mailer.conf は通常のファイルなので、`force` で張り替える（`ln -sfn`）。張れていれば何もしない
link '/etc/mail/mailer.conf' do
  to '/usr/local/share/postfix/mailer.conf.postfix'
  force true
end
