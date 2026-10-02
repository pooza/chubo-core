exit unless node.platform == 'freebsd'

require 'digest/md5'

# ⚠⚠ **anacron は入れない。**経緯と理由は crontab.erb の先頭へ書いた
# （pooza/chubo2#243）。一度入れてしまったので、明示的に外す。
# ⚠ **`package ... action :remove` は使えない。**specinfra の
# `Specinfra::Command::Freebsd::Base::Package` に remove が実装されておらず、
# NotImplementedError でレシピがその場で止まる。
# ⚠⚠ **dry-run では再現しない**（action を実行しないので通ってしまう）。
execute 'pkg delete -y anacron' do
  only_if 'pkg info anacron > /dev/null 2>&1'
end

file '/usr/local/etc/anacrontab' do
  action :delete
end

# ⚠⚠ **分は rand ではなくノード名から決定的に導く。**元は `rand(0..59)` だったが、
# ERB は**レンダするたび別の値**を出すので、`/etc/crontab` が常に「差分あり」になり、
# 適用のたびに periodic の実行時刻がシャッフルされていた（pooza/chubo2#121 の dry-run で
# **全 25 ノードが 1 件残らずこれ**）。⚠ **ドリフト検知のノイズ源としては最悪の部類**で、
# 「毎回出るから見ない」ことを覚えてしまう。
# ノードごとに違う値になる（＝全機が同時に走らない）という元の意図は保たれる。
minutes = ['hourly', 'daily', 'weekly', 'monthly'].to_h do |key|
  [key, Digest::MD5.hexdigest("#{node.nodename}/#{key}").to_i(16) % 60]
end

template '/etc/crontab' do
  source 'templates/crontab.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
  variables(minutes: minutes)
end

# ⚠⚠ **同じ瞬間に起動した root のジョブの CMD 行は、2 本目以降がカーネルで捨てられる**
# （pooza/chubo2#247）。FreeBSD 14 の unix(4) datagram は、接続した送信者が未読のまま
# 切断すると、受け手の「接続なしの送信者用キュー」が空のときだけ未読分を移し、
# **空でなければ捨てる**（`uipc_usrreq.c` の `unp_disconnect`。洪水対策の仕様）。
# cron の子は 1 行送って即 exec するので、2 つ同時に終わると 2 本目が消える。
# 2026-10-03 の gomander で atrun の行の約 12% が欠けていた。**ジョブは走っている。**
# `-J` の sleep は CMD を記録する**前**にある（`do_command.c`）ので、起動をばらせば減る。
# ⚠ sleep は秒単位なので、同じ秒に当たった組は残る（15 なら約 7%）。
# **cron.log を「走ったか」の根拠にしないこと**は変わらない。
# ⚠ `-s` は書かない。/etc/rc.d/cron が `cron_dst=YES`（既定）で自分で足す（書くと 2 重になる）。
cron_flags = "-J #{node.dig('cron', 'root_jitter') || 15}"
execute "sysrc cron_flags='#{cron_flags}'" do
  not_if "test \"$(sysrc -n cron_flags)\" = '#{cron_flags}'"
  notifies :restart, 'service[cron]'
end

service 'cron'

template '/etc/periodic.conf' do
  source 'templates/periodic.conf.erb'
  owner 'root'
  group node.dig('wheel', 'group')
  mode '0644'
end

# ⚠ **`frequently` も作る。**`/etc/crontab` に `*/5 * * * * root periodic frequently` が
# あるのにこのディレクトリだけ無かったので、**5 分ごとの枠が使えなかった**
# （pooza/chubo2#244 で Kuma へのハートビートを置くときに発覚）。
['frequently', 'hourly', 'daily', 'weekly', 'monthly'].each do |period|
  directory File.join('/usr/local/etc/periodic', period) do
    owner 'root'
    group node.dig('sudo', 'group')
    mode '0775'
  end
end
