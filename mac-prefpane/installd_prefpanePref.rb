#
#  installd_prefpanePref.m
#  installd-prefpane
#
#  Created by James Mead on 18/09/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'osx/cocoa'

include OSX

class PrefPaneinstalld_prefpane < NSPreferencePane

	def mainViewDidLoad
		NSLog("installd_prefpane PreferencePane loaded")
	end
	
end
