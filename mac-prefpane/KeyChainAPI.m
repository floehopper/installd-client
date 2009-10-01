#import "KeyChainAPI.h"

#include <Security/SecKeychain.h>
#include <Security/SecKeychainItem.h>
#include <Security/SecTrustedApplication.h>
#include <Security/SecACL.h>
  
@implementation KeyChainAPI

-(OSStatus)addGenericPassword:(NSString*)service account:(NSString*)account password:(NSString*)password otherAppPath:(NSString*)otherAppPath
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  OSStatus err;
  SecKeychainItemRef item = nil;
  const char *serviceUTF8 = [service UTF8String];
  const char *accountUTF8 = [account UTF8String];
  const char *passwordUTF8 = [password UTF8String];
  
  //Create initial access control settings for the item:
  SecAccessRef access = [self createAccess:service otherAppPath:otherAppPath];
  
  //Following is the lower-level equivalent to the
  // SecKeychainAddInternetPassword function:
  
  //Set up the attribute vector (each attribute consists
  // of {tag, length, pointer}):
  SecKeychainAttribute attrs[] = {
    { kSecServiceItemAttr, strlen(serviceUTF8), (char *)serviceUTF8 },
    { kSecAccountItemAttr, strlen(accountUTF8), (char *)accountUTF8 },
    { kSecLabelItemAttr, strlen(serviceUTF8), (char *)serviceUTF8 }
  };
  
  SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]), attrs };
  
  err = SecKeychainItemCreateFromContent(
    kSecGenericPasswordItemClass,
    &attributes,
    strlen(passwordUTF8),
    passwordUTF8,
    NULL, // use the default keychain
    access,
    &item
  );
  
  if (access) CFRelease(access);
  if (item) CFRelease(item);
  
  [pool release];
  
  return err;
}

 -(SecAccessRef)createAccess:(NSString *)accessLabel otherAppPath:(NSString*)otherAppPath
 {
   OSStatus err;
   SecAccessRef access=nil;
   NSArray *trustedApplications=nil;
   
   //Make an exception list of trusted applications; that is,
   // applications that are allowed to access the item without
   // requiring user confirmation:
   SecTrustedApplicationRef myself, someOther;
   //Create trusted application references; see SecTrustedApplications.h:
   err = SecTrustedApplicationCreateFromPath(NULL, &myself);
   err = SecTrustedApplicationCreateFromPath([otherAppPath UTF8String], &someOther);
   trustedApplications = [NSArray arrayWithObjects:(id)myself,
                          (id)someOther, nil];
   //Create an access object:
   err = SecAccessCreate((CFStringRef)accessLabel,
                         (CFArrayRef)trustedApplications, &access);
   
   if (err) return nil;
   
   return access;
 }

@end

// Ruby module initialization function
// So we can build a bundle and use it from RubyCocoa
void Init_keychainapi(){}

