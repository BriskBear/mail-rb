# Import external tools
require 'active_support/core_ext/hash/keys'
require 'yaml'

class Configuration
  attr_accessor :table

  def initialize()
    @table = YAML.load_file('config.yml').symbolize_keys
  end

  def method_missing(method_name)
    @table.keys.include?(method_name.to_sym) ? @table[method_name.to_sym] : (raise "#{method_name} is not a configured attibute.")
  end
end

@config = Configuration.new
