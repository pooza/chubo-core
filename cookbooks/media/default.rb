exit unless node.dig('media', 'enable')

# Mastodon/Misskey のメディア処理に要る外部依存。
# Mastodon(FreeBSD)=ffmpeg + libvips + ImageMagick、Misskey(Ubuntu)=ffmpeg（画像は sharp 同梱）。
packages = node.dig('media', 'packages') || case node.platform
                                            when 'freebsd' then ['ffmpeg', 'vips', 'ImageMagick7']
                                            when 'ubuntu' then ['ffmpeg']
                                            else []
                                            end

packages.each do |pkg|
  package pkg
end
