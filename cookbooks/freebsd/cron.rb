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
