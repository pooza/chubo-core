exit unless node.platform == 'freebsd'
exit unless (device = node.dig('swap', 'device'))

fstab_line = "#{device} none swap sw 0 0"

execute "add #{device} to fstab" do
  command "echo '#{fstab_line}' >> /etc/fstab"
  not_if "grep -q '#{device}' /etc/fstab"
end

execute "swapon #{device}" do
  not_if "swapctl -l | grep -q '#{device}'"
end
