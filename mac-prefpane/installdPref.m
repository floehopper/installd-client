//
//  installdPref.m
//  installd
//
//  Created by James Mead on 19/09/2009.
//  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
//

@interface installdLoader : NSObject
{}
@end
@implementation installdLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("installdPref.rb", [installdLoader class], nil);
}
