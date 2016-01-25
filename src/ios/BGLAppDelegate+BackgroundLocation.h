#import <Foundation/Foundation.h>
#import "AppDelegate.h"


@interface AppDelegate (BGLAppDelegate)

- (BOOL)_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;

- (BOOL)prepareCategory;
- (BOOL)startPoolingLocation;

@end
