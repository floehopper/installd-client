@interface InstalldLoader : NSObject
{}
@end
@implementation InstalldLoader
@end

static void __attribute__((constructor)) loadRubyPrefPane(void)
{
  RBBundleInit("installd_pref.rb", [InstalldLoader class], nil);
}
