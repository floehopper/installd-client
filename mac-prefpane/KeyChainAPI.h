#import <Cocoa/Cocoa.h>

#include <Security/SecAccess.h>

@interface KeyChainAPI : NSObject {
}

-(OSStatus)addGenericPassword:(NSString*)service account:(NSString*)account password:(NSString*)password otherAppPath:(NSString*)otherAppPath;

-(SecAccessRef)createAccess:(NSString*)accessLabel otherAppPath:(NSString*)otherAppPath;

@end
