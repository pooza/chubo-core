require 'ginseng'
require 'open3'
require 'timeout'
require 'facets/time'

# ⚠ `Ginseng::CommandLine` は controller.rb では実行時にしか触らないので require が
# 要らなかったが、こちらは**継承なので読み込み時に解決される**。ginseng を明示的に
# require しないと `uninitialized constant Chubo::Ginseng` で落ちる。

module Chubo
  # 実行しながら出力を流す CommandLine（pooza/chubo2#9）。
  #
  # ⚠ `Ginseng::CommandLine#exec` は `Open3.capture3` なので、**プロセスが終わるまで
  # 1 バイトも返らない**。ruby のビルドや `pkg update` は数十分かかるため、端末からは
  # 固まったようにしか見えない。
  #
  # ⚠⚠ **流す先は $stderr。**$stdout はレシピの実行報告（Slack へ投げる本文と同じもの）
  # に使われていて、`tools/drift-sweep.rb` のように**それをパースする側がいる**。
  # 進捗を $stdout に混ぜると、同じ `INFO :` 行が生ログと報告本文とで二重に出る。
  class StreamCommandLine < Ginseng::CommandLine
    def initialize(args = [], io: $stderr)
      super(args)
      @io = io
    end

    def exec(timeout: nil)
      secs = Time.elapse do
        Bundler.with_unbundled_env do
          block = proc {stream}
          timeout ? Timeout.timeout(timeout, &block) : block.call
        end
      end
      log_exec(secs, success: @status.zero?)
      return @status
    end

    private

    def stream
      buffers = {stdout: [], stderr: []}
      Open3.popen3(@env.stringify_keys, to_s, chdir: dir) do |stdin, stdout, stderr, thread|
        stdin.close
        # ⚠ stdout を読み切ってから stderr を読むと、stderr のパイプが埋まった時点で
        # 相手が書き込みでブロックし、こちらは stdout の EOF を待ち続けて刺さる。
        # **両方を同時に読む**こと。
        readers = {stdout => buffers[:stdout], stderr => buffers[:stderr]}
        threads = readers.map do |io, buffer|
          Thread.new do
            io.each_line do |line|
              buffer.push(line)
              @io.print(line)
            end
          end
        end
        threads.each(&:join)
        @pid = thread.pid
        @status = thread.value.to_i
      end
      @stdout = buffers[:stdout].join
      @stderr = buffers[:stderr].join
    end
  end
end
