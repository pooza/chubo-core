exit unless node.dig('rbenv', 'enable')
exit unless node.platform == 'freebsd'

deployer = node.dig('deployer', 'user')

# rbenv + ruby-build
package 'rbenv'
package 'ruby-build'

# Ruby ビルドに必要なパッケージ
['autoconf', 'bison', 'readline', 'openssl', 'libyaml', 'libffi', 'rust'].each do |pkg|
  package pkg
end

# Ruby バージョンのビルド（YJIT無効でビルドされていた場合は再ビルド）
node.dig('rbenv', 'versions')&.each do |version|
  execute "rbenv install #{version} for #{deployer}" do
    command "rbenv install #{version}"
    user deployer
    not_if "RBENV_VERSION=#{version} rbenv exec ruby -e 'exit RubyVM::YJIT.enabled?' 2>/dev/null"
  end
end

# グローバルバージョン設定
if (global = node.dig('rbenv', 'global'))
  execute "rbenv global #{global} for #{deployer}" do
    command "rbenv global #{global}"
    user deployer
  end
end
