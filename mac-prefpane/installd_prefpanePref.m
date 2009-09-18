//
//  installd_prefpanePref.m
//  installd-prefpane
//
//  Created by James Mead on 18/09/2009.
//  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
//

@interface installd_prefpaneLoader : NSObject
{}
@end
@implementation installd_prefpaneLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("installd_prefpanePref.rb", [installd_prefpaneLoader class], nil);
}
