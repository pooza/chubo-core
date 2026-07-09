exit unless node.dig('media', 'enable')

# Mastodon/Misskey のメディア処理に要る外部依存。
# Misskey 自身は画像処理に sharp を同梱するが、同居するモロヘイヤの ruby-vips が
# libvips.so を dlopen するため Ubuntu でも libvips が要る（本番 sweep と同じ構成）。
packages = node.dig('media', 'packages') || case node.platform
                                            when 'freebsd' then ['ffmpeg', 'vips', 'ImageMagick7']
                                            when 'ubuntu' then ['ffmpeg', 'imagemagick', 'libvips-dev']
                                            else []
                                            end

packages.each do |pkg|
  package pkg
end
