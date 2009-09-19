//
//  InstalldPref.m
//  Installd
//
//  Created by James Mead on 19/09/2009.
//  Copyright (c) 2009 Floehopper Ltd. All rights reserved.
//

@interface InstalldLoader : NSObject
{}
@end
@implementation InstalldLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("InstalldPref.rb", [InstalldLoader class], nil);
}
