#
#  InstalldPref.m
#  Installd
#
#  Created by James Mead on 19/09/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'osx/cocoa'

include OSX

OSX.require_framework 'PreferencePanes'

class PrefPaneInstalld < NSPreferencePane

  def mainViewDidLoad
    NSLog("PrefPaneInstalld: mainViewDidLoad")
  end
  
  def willSelect
    NSLog("PrefPaneInstalld: willSelect")
  end
  
  def didSelect
    NSLog("PrefPaneInstalld: didSelect")
  end
  
  def shouldUnselect
    NSLog("PrefPaneInstalld: shouldUnselect")
    NSUnselectNow
  end
  
  def willUnselect
    NSLog("PrefPaneInstalld: willUnselect")
  end
  
  def didUnselect
    NSLog("PrefPaneInstalld: didUnselect")
  end
  
end
