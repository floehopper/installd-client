#
#  sync_controller.rb
#  installd
#
#  Created by James Mead on 09/07/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'sync'

class SyncController < OSX::NSObject

  ib_outlets :label
  
  ib_action :sync do |sender|
    Sync.sync
    @label.stringValue = 'Complete'
  end
  
end