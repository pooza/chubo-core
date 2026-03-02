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
        command.exec
        report_result(node, recipe, command)
      end
    ensure
      FileUtils.rm_f(data['path'])
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

    def create_node_data(name)
      node_data = YAML.load_file(File.join(Environment.dir, 'config/node', "#{name}.yaml"))
      platform = node_data['platform']
      data = YAML.load_file(File.join(Environment.dir, 'config/platform', "#{platform}.yaml"))
      data['cookbooks_dir'] = File.join(Environment.dir, 'app/cookbooks')
      data['nodename'] = name.sub(/\.local$/, '')
      data['users'] = users
      data.deep_merge!(node_data)
      data.deep_merge!(YAML.load_file(File.join(Environment.dir, 'config/local.yaml')))
      return data
    end

    def create_node_file(data)
      path = File.join(Environment.dir, 'tmp/node', "#{data.to_json.adler32}.yaml")
      File.write(path, data.to_yaml)
      return path
    end

    def create_command(data, recipe)
      return Ginseng::CommandLine.new([
        'itamae',
        'ssh',
        '-h', data['nodename'],
        '-u', data.dig('node', 'ssh', 'user') || ENV.fetch('USER', nil),
        '-p', data.dig('node', 'ssh', 'port') || 22,
        '--node-yaml', data['path'],
        find_recipe(recipe)
      ])
    end

    def find_recipe(recipe)
      local = File.join(Environment.dir, 'app/cookbooks', "#{recipe}.rb")
      return local if File.exist?(local)

      shared = File.join(Chubo::Core.cookbooks_dir, "#{recipe}.rb")
      return shared if File.exist?(shared)

      raise "Recipe not found: #{recipe}"
    end

    def report_result(node, recipe, command)
      return unless command.stdout.include?('Recipe:') || command.stderr.present?
      puts create_body(node, recipe, command) if single_node?
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
