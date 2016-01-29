#import <Foundation/Foundation.h>
#import "AppDelegate.h"


@interface AppDelegate (BackgroundLocation)

- (BOOL)_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
- (void)_applicationWillTerminate:(UIApplication *)application;

@end
