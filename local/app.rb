require 'fileutils'
require 'hpricot'

module Local
  
  class App
    
    attr_reader :attributes
    
    def initialize(attributes = {})
      @attributes = attributes
    end
    
    def [](key)
      @attributes[key]
    end
    
    def self.all_by_name
      # maybe use a tmp directory instead?
      FileUtils.rm_rf('unzipped')
      FileUtils.mkdir_p('unzipped')
      
      apps_pattern = File.join(ENV['HOME'], 'Music', 'iTunes', 'Mobile Applications', '*.ipa')
      
      app_names = {}
      Dir[apps_pattern].each do |app_file|
        app_name = File.basename(app_file, '.ipa')
        unzip_dir = File.join('unzipped', app_name)
        plist = File.join(unzip_dir, 'iTunesMetadata.plist')
        
        # maybe do this in Ruby?
        `unzip -d "#{unzip_dir}" "#{app_file}" iTunesMetadata.plist`
        `plutil -convert xml1 "#{plist}"`
        
        doc = Hpricot::XML(File.read(plist))
        
        itemName = (doc/'plist'/'dict'/"key[text()='itemName']")[0].next_sibling.inner_text
        itemId = (doc/'plist'/'dict'/"key[text()='itemId']")[0].next_sibling.inner_text
        softwareIcon57x57URL = (doc/'plist'/'dict'/"key[text()='softwareIcon57x57URL']")[0].next_sibling.inner_text
        
        app_names[itemName] = new('name' => itemName, 'item_id' => itemId, 'icon_url' => softwareIcon57x57URL)
      end
      
      FileUtils.rm_rf('unzipped')
      app_names
    end
    
  end
  
end