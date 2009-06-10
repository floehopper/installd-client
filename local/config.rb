require 'fileutils'

module Local
  
  class Config
    
    FILENAME = 'config.yml'
    
    def initialize(attributes)
      @attributes = attributes
    end
    
    def [](key)
      @attributes[key]
    end
    
    def []=(key, value)
      @attributes[key] = value
    end
    
    def save
      File.open(FILENAME, 'w') do |file|
        file.puts(@attributes.to_yaml)
      end
    end
    
    class << self
    
      def load
        attributes = YAML.load_file(FILENAME)
        new(attributes)
      rescue
        new({})
      end
      
    end
    
  end
  
end