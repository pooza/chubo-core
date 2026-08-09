exit unless node.dig('certbot', 'enable')

deploy_hook = node.dig('certbot', 'deploy_hook') || 'service nginx onereload'
certbot_package = node.dig('certbot', 'package') || 'certbot'

package certbot_package

# ⚠⚠ **`certbot.domains` に足しただけでは証明書は出ない**、という状態を解消するための発行。
#
# 以前はここが `certbot renew`（＝既存の更新）しか叩かず、**新規ドメインの初回発行を
# 誰も担当していなかった**。nginx cookbook は宣言どおり vhost を書くので、
# 「証明書が無い → nginx が起動できない → ACME の検証も通らない」で自力では抜けられない
# 詰みになる（2026-08-09 に noah で発生。pooza/chubo2#163）。
#
# ⚠ **nginx より後に流すこと**（`--recipes=nginx,certbot`）。HTTP-01 は :80 で検証するので、
# nginx がそのドメインの vhost を持って起動している必要がある。nginx cookbook は証明書が
# 未発行のドメインには :80 だけの vhost を出すので、この順番なら 1 回で発行まで到達する。
# ⚠ **443 が生えるのは次の適用**（発行済みになってから nginx を流し直したとき）。
#
# 既に発行済みなら叩かない。**SAN として他の証明書に含まれている場合も発行しない**
# （例: gomander の cure-api.precure.ml は precure.ml の証明書の SAN。ここで
# `test -d live/<domain>` だけを見ると、不要な lineage をもう 1 本作ってしまう）。
letsencrypt_dir = node.platform == 'freebsd' ? '/usr/local/etc/letsencrypt' : '/etc/letsencrypt'
webroot = node.dig('certbot', 'webroot') ||
          (node.platform == 'freebsd' ? '/usr/local/www/nginx' : '/var/www/html')
email = node.dig('wheel', 'email')

(node.dig('certbot', 'domains') || []).each do |domain|
  execute "certbot certonly #{domain}" do
    command "certbot certonly --webroot -n -w #{webroot} -d #{domain} -m #{email} --agree-tos"
    # ⚠ not_if は 1 つしか持てない（2 回書くと後ろが前を上書きする）ので || で繋ぐ。
    not_if %(test -d #{letsencrypt_dir}/live/#{domain} || ) +
           %(certbot certificates 2>/dev/null | tr -s ' ' '\\n' | grep -qFx '#{domain}')
  end
end

case node.platform
when 'freebsd'
  execute 'enable weekly certbot' do
    command 'sysrc -f /etc/periodic.conf weekly_certbot_enable="YES"'
    not_if 'grep -q \'weekly_certbot_enable="YES"\' /etc/periodic.conf'
  end

  execute 'set certbot deploy hook' do
    command "sysrc -f /etc/periodic.conf weekly_certbot_deploy_hook=\"#{deploy_hook}\""
  end
when 'ubuntu'
  template '/etc/cron.weekly/certbot' do
    source 'templates/certbot.sh.erb'
    owner 'root'
    group node.dig('root', 'group')
    mode '0755'
  end

  execute 'certbot renew'
end
