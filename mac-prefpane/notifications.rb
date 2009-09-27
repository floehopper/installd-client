require 'osx/cocoa'

module Installd
  
  class Notifications
    
    include OSX
    
    SYNC_DID_COMPLETE = "InstalldSyncDidComplete"
    
    def initialize(bundle_identifier)
      @bundle_identifier = bundle_identifier
      @center = NSDistributedNotificationCenter.defaultCenter
    end
    
    def register_for_sync_did_complete(observer, selector)
      @center.addObserver_selector_name_object(
        observer,
        selector,
        SYNC_DID_COMPLETE,
        @bundle_identifier
      )
    end
    
    def sync_did_complete(status)
      @center.postNotificationName_object_userInfo_deliverImmediately(
        SYNC_DID_COMPLETE,
        @bundle_identifier,
        { 'status' => status },
        true
      )
    end
    
  end
  
end