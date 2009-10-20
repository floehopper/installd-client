require 'osx/cocoa'

module Installd
  
  class Notifications
    
    include OSX
    
    SYNC_DID_BEGIN = "InstalldSyncDidBegin"
    SYNC_DID_COMPLETE = "InstalldSyncDidComplete"
    CHECK_FOR_UPDATES = "InstalldCheckForUpdates"
    SHOW_STATUS_BAR_ITEM = "InstalldShowStatusBarItem"
    
    def initialize(bundle_identifier)
      @bundle_identifier = bundle_identifier
      @center = NSDistributedNotificationCenter.defaultCenter
    end
    
    def register_for_sync_did_begin(observer, selector)
      @center.addObserver_selector_name_object(
        observer,
        selector,
        SYNC_DID_BEGIN,
        @bundle_identifier
      )
    end
    
    def register_for_sync_did_complete(observer, selector)
      @center.addObserver_selector_name_object(
        observer,
        selector,
        SYNC_DID_COMPLETE,
        @bundle_identifier
      )
    end
    
    def register_for_check_for_updates(observer, selector)
      @center.addObserver_selector_name_object(
        observer,
        selector,
        CHECK_FOR_UPDATES,
        @bundle_identifier
      )
    end
    
    def register_for_show_status_bar_item(observer, selector)
      @center.addObserver_selector_name_object(
        observer,
        selector,
        SHOW_STATUS_BAR_ITEM,
        @bundle_identifier
      )
    end
    
    def sync_did_begin
      @center.postNotificationName_object_userInfo_deliverImmediately(
        SYNC_DID_BEGIN,
        @bundle_identifier,
        {},
        true
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
    
    def check_for_updates
      @center.postNotificationName_object_userInfo_deliverImmediately(
        CHECK_FOR_UPDATES,
        @bundle_identifier,
        {},
        true
      )
    end
    
    def show_status_bar_item(state)
      @center.postNotificationName_object_userInfo_deliverImmediately(
        SHOW_STATUS_BAR_ITEM,
        @bundle_identifier,
        { 'state' => state },
        true
      )
    end
    
  end
  
end