exit unless node.platform == 'freebsd'

require 'digest/md5'

package 'anacron'

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

['hourly', 'daily', 'weekly', 'monthly'].each do |period|
  directory File.join('/usr/local/etc/periodic', period) do
    owner 'root'
    group node.dig('sudo', 'group')
    mode '0775'
  end
end
