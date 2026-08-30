module Chubo
  class Controller
    attr_reader :options, :config

    def initialize(options)
      @options = options
      @config = Config.instance
    end

    def exec
      if single_node?
        exec_node(nodes.first)
      else
        Parallel.each(nodes, in_processes: Parallel.processor_count) do |node|
          exec_node(node)
        end
      end
    end

    def exec_node(node)
      data = create_node_data(node)
      data['path'] = create_node_file(data)
      recipes.each do |recipe|
        command = create_command(data, recipe)
        secs = Time.elapse {command.exec}
        report_progress(node, recipe, command, secs)
        report_result(node, recipe, command)
      end
    ensure
      FileUtils.rm_f(data['path'])
    end

    # 端末に向いているか。⚠⚠ **進捗表示はここが真のときだけ**にする。
    # `tools/drift-sweep.rb` のように出力を捕まえて機械的に読む側がいるので、
    # パイプに向けたときの挙動は従来と 1 バイトも変えない（pooza/chubo2#9）。
    def tty?
      return $stderr.tty?
    end

    # ⚠ dry-run では流さない。**dry-run の値は整形済みの報告のほう**にあり
    # （ドリフト棚卸し・pooza/chubo2#121）、生ログを重ねても読みにくくなるだけ。
    # 長いのは ruby のビルドや pkg update ＝ 実適用の側。
    def stream?
      return tty? && single_node? && !dry_run?
    end

    def webhook
      @webhook ||= WebhookService.new(config['/slack/webhook'])
      return @webhook
    end

    def nodes
      nodes = options[:nodes].to_s.split(',').compact.to_set
      if nodes.empty?
        finder = Ginseng::FileFinder.new
        finder.dir = File.join(Environment.dir, 'config/node')
        finder.patterns.push('*.yaml')
        nodes.merge(finder.exec.map {|f| File.basename(f, '.yaml')})
      end
      return nodes
    end

    def single_node?
      return nodes.length == 1
    end

    def dry_run?
      return options[:'dry-run'].present?
    end

    def recipes
      recipes = options[:recipes].to_s.split(',').select(&:present?).map do |recipe|
        recipe += '/default' unless recipe.match?('/')
        recipe.sub!(/\.rb$/, '')
        recipe
      end
      return recipes.to_set
    end

    def users
      unless @users
        @users = {}
        Dir.glob(File.join(Environment.dir, 'config/user/*.yaml')).each do |path|
          @users[File.basename(path, '.yaml')] = YAML.load_file(path)
        end
      end
      return @users
    end

    # ⚠⚠ **廃止した宣言が残っていたら、黙って無視せずここで落とす。**
    # `ruby.version` は「pkg / ports の版」と「rbenv でビルドする版」の 2 つの局面を
    # 1 つのキーに背負わせていて、**いつ流したかで意味が変わる ＝ 原理的に冪等にならない**
    # （pooza/chubo2#71）。`ruby.system.version` / `ruby.rbenv.version` に分けたので、
    # 旧キーのまま流すと「宣言したのに効かない」が黙って再発する。
    # `rbenv.global` / `rbenv.versions` はどの cookbook からも読まれていない死んだ宣言。
    # ⚠ `rbenv.enable` は生きている（zsh / bash の shell 初期化テンプレートが読む）。
    LEGACY_NODE_KEYS = {
      ['ruby', 'version'] =>
        'ruby.system.version（pkg / ports の版）と ruby.rbenv.version（rbenv でビルドする版）へ分割',
      ['ruby', 'global'] => 'ruby.rbenv.global',
      ['rbenv', 'global'] => '廃止。どの cookbook からも読まれていない（ruby.rbenv.global を使う）',
      ['rbenv', 'versions'] => '廃止。どの cookbook からも読まれていない（ruby.rbenv.version を使う）',
    }.freeze

    def validate_node_data(data, name)
      errors = LEGACY_NODE_KEYS.filter_map do |keys, hint|
        next unless data.dig(*keys)

        "#{name}: 廃止された宣言 `#{keys.join('.')}` が残っている → #{hint}"
      end
      return if errors.empty?

      raise "#{errors.join("\n")}\n(pooza/chubo2#71)"
    end

    def create_node_data(name)
      node_data = YAML.load_file(File.join(Environment.dir, 'config/node', "#{name}.yaml"))
      platform = node_data['platform']
      data = YAML.load_file(File.join(Environment.dir, 'config/platform', "#{platform}.yaml"))
      data['cookbooks_dir'] = File.join(Environment.dir, 'app/cookbooks')
      data['nodename'] = name.sub(/\.local$/, '')
      data['users'] = users
      data.deep_merge!(node_data)
      data.deep_merge!(YAML.load_file(File.join(Environment.dir, 'config/local.yaml')))
      validate_node_data(data, name)
      return data
    end

    def create_node_file(data)
      path = File.join(Environment.dir, 'tmp/node', "#{data.to_json.adler32}.yaml")
      File.write(path, data.to_yaml)
      return path
    end

    def create_command(data, recipe)
      args = [
        'itamae',
        'ssh',
        '-h', data['nodename'],
        '-u', data.dig('node', 'ssh', 'user') || ENV.fetch('USER', nil),
        '-p', data.dig('node', 'ssh', 'port') || 22,
        '--node-yaml', data['path']
      ]
      args.push('--dry-run') if dry_run?
      args.push(find_recipe(recipe))
      return StreamCommandLine.new(args) if stream?

      return Ginseng::CommandLine.new(args)
    end

    def find_recipe(recipe)
      local = File.join(Environment.dir, 'app/cookbooks', "#{recipe}.rb")
      return local if File.exist?(local)

      shared = File.join(Chubo::Core.cookbooks_dir, "#{recipe}.rb")
      return shared if File.exist?(shared)

      raise "Recipe not found: #{recipe}"
    end

    # 複数ノードを並列で回している間は、どのノードのどのレシピが終わったのかが
    # 全く分からない（報告は最後にまとめて出る）。⚠ 子プロセスから出すので順不同。
    def report_progress(node, recipe, command, secs)
      return unless tty?
      return if stream?

      mark = command.status.zero? ? 'ok' : 'NG'
      warn "#{mark} #{node} #{recipe} (#{secs.round(1)}s)"
    end

    def report_result(node, recipe, command)
      return unless command.stdout.include?('Recipe:') || command.stderr.present?
      if dry_run?
        # dry-run はドリフトの調査（pooza/chubo2#121）であって作業ではない。
        # 全ノードを回すと Slack が埋まるだけなので、端末にだけ出す。
        puts create_body(node, recipe, command)
        return
      end
      # ⚠ ストリーミングで既に流し終えているものを、整形して二度出さない。
      puts create_body(node, recipe, command) if single_node? && !stream?
      webhook.post(create_body(node, recipe, command))
    end

    def create_body(node, recipe, command)
      body = ["node: #{node}", "recipe: #{recipe}"]
      body.push('```', format(command.stdout), '```') if command.stdout.present?
      body.push('```', format(command.stderr), '```') if command.stderr.present?
      return body.join("\n")
    end

    def format(src)
      body = src.strip
      body.gsub!(/\e\[\d{1,3}[mK]/, '')
      return body
    end
  end
end
