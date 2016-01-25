#import <Foundation/Foundation.h>
#import "AppDelegate.h"


@interface AppDelegate (BGLAppDelegate)

- (BOOL)prepareCategory;

- (BOOL)_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

@end
