require File.join(File.dirname(__FILE__), 'app')
require File.join(File.dirname(__FILE__), 'install')
require 'activeresource'

module Remote
  
  class User < ActiveResource::Base
    
    def apps
      get(:apps).map { |attributes| App.new(attributes) }
    end
    
    def installs
      installs = get(:installs).map { |attributes| Install.new(attributes) }
      class << installs
        def find_by_app(app)
          detect { |install| install.app_id == app.id }
        end
      end
      installs
    end
    
    def create_install(attributes = {})
      Install.create(attributes.merge(:user_id => self.id))
    end
    
    def apps_by_name
      apps.inject({}) do |result, app|
        result[app.name] = app
        result
      end
    end
    
    class << self
      
      def find_by_login(login)
        find(:first, :params => { :login => login })
      end
      
    end
    
  end
  
end
