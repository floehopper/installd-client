require 'activeresource'

module Remote
  
  class Install < ActiveResource::Base
    
    class << self
      
      def create(attributes ={})
        hash = attributes.dup
        user = hash.delete(:user)
        hash[:user_id] = user.id if user
        app = hash.delete(:app)
        hash[:app_id] = app.id if app
        super(hash)
      end
      
    end
    
  end

end