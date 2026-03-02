require_relative 'controller'

module Chubo
  module Core
    def self.dir
      return File.expand_path('../..', __dir__)
    end

    def self.cookbooks_dir
      return File.join(dir, 'cookbooks')
    end
  end
end
