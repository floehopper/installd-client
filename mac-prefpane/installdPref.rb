#
#  installdPref.m
#  installd
#
#  Created by James Mead on 19/09/2009.
#  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
#

require 'osx/cocoa'

include OSX

class PrefPaneinstalld < NSPreferencePane

	def mainViewDidLoad
		NSLog("installd PreferencePane loaded")
	end
	
end
