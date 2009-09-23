@interface InstalldLoader : NSObject
{}
@end
@implementation InstalldLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
	RBBundleInit("InstalldPref.rb", [InstalldLoader class], nil);
}
