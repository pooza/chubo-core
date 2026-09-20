exit unless node.dig('nginx', 'enable')

# アクセスの急増を Uptime Kuma の push モニタへ送る（pooza/chubo2#118）。
#
# ⚠⚠ **なぜ要るのか。**2026-08-02 の分散ボット（load 24.6・504 が 808 件）と同じものが
# 2026-09-21 時点でも動き続けていたのに、**6 日以上のあいだ誰も気づいていなかった。**
# 504 が出ないうちは monit にも Kuma の外形監視にも乗らないので、
# **可視なのは転送量だけ**という状態だった。
#
# 🔴 **遮断の仕組みではない。**相手は 1,097 個の /24 に散っていて IPv6 が 65%、
# UA は実在の Chrome を名乗る。**UA 遮断も per-IP のレートリミットも使えない**ことを
# 実測で確認したうえで、「受け止める」のではなく**「気づく」ほうを入れた**。
#
# ⚠ 送信は `periodic frequently`（*/5）。Kuma 側の interval も 300s に揃えること
#   （ずれると 1 回の取りこぼしがそのまま DOWN になる。#244 で踏んだ型）。
# ⚠ **`nginx.surge.enable` を宣言したノードだけ。**`nginx.enable` で選ぶと
#   開発機（dev24 / dev25 / dev26）まで当たる。見張る価値があるのは公開 vhost を
#   持つノードだけなので、宣言を正典にする。
# ⚠ トークンは `tools/kuma-register-nginx.py --apply`（chubo2）が発行する
#   （宣言 → 登録 → トークンを宣言へ書き戻す、の 2 段）。
#
# ⚠⚠ **FreeBSD だけ。**Ubuntu には `periodic frequently` に相当する 5 分の口が無く、
#   対象ノード（gomander / shallu / zugoga）はいずれも FreeBSD なので、そちらは作らない。
#   兄弟（writersbase-env）は Ubuntu なので、この宣言を足しても何も起きない。
exit unless node.dig('nginx', 'surge', 'enable')
exit unless node.platform == 'freebsd'

# ⚠ 宣言はあるがトークンがまだ無い状態（登録前）では何も置かない。
token = node.dig('nginx', 'surge', 'kuma_push_token')
exit unless token

directory '/var/db/chubo' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0755'
end

# 🔴 **1 回ぶんの差分しか読まない。**アクセスログは日に 300MB を超えるので、
# 毎回頭から読むと 5 分ごとに全部走査することになる。
# 前回のバイト位置をここに置き、`tail -c +N` で増えたぶんだけ数える。
directory '/var/db/chubo/nginx-surge' do
  owner 'root'
  group node.dig('root', 'group')
  mode '0700'
end

# ⚠ FreeBSD の periodic は実行順を数字で決める。monit の push（950）の後に置く。
template '/usr/local/etc/periodic/frequently/955.kuma-push-nginx' do
  source 'templates/kuma-push-surge.sh.erb'
  owner 'root'
  group node.dig('root', 'group')
  # ⚠ push URL はそれ自体が資格情報なので 0700（#184 で sops へ移す対象）。
  mode '0700'
  variables(
    token:,
    base: node.dig('nginx', 'surge', 'kuma_push_base') || 'https://uptime.b-shock.org/api/push',
    # ⚠⚠ **req/分をしきい値にしてはいけない。**遮断済みのボットを除いてもなお
    # **11,448 req/分の山が立つ**（2026-09-07 10:53・gomander の実測）。
    # 正常と異常を req では分けられないので、**鳴らすのは送出量と 5xx だけ**にする。
    #
    # ⚠ 送出量の既定 700 MB/5分（＝ 140 MB/分・197 GB/日ペース）は実測から決めた:
    #   正常のピーク **330 MB/5分**（2026-09-07 22:10・ボット除外）＜ 700 ＜
    #   Exa 洪水の **840 MB/5分**（2026-09-20・170 MB/分が数時間）。
    # ⚠ 2026-09-21 時点で居座っている分散ボットは 134 MB/5分なので**鳴らない**
    #   （遮断しないと決めた相手なので、鳴らしても対処が無い）。
    megabytes: node.dig('nginx', 'surge', 'megabytes') || 700,
    # ⚠ 2026-08-02 は 504 が 1 日 808 件・ピークで 20,000 req あたり 291 件。
    #   平常は 1 日 1〜18 件なので、5 分で 20 件は平常では出ない。
    server_errors: node.dig('nginx', 'surge', 'server_errors') || 20,
  )
end
