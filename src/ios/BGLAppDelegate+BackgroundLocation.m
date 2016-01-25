#import "BGLAppDelegate+BackgroundLocation.h"
#import "BGLLocationTracker.h"

#include <objc/runtime.h>


@interface BGLAppDelegate_p : NSObject {

}

@property LocationTracker*     locationTracker;
@property (nonatomic) NSTimer* locationUpdateTimer;

- (void)updateLocation;

@end


@implementation BGLAppDelegate_p

//Class method to make sure the share model is synch across the app
+ (id)inst
{
    static id sharedMyModel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyModel = [[self alloc] init];
    });
    return sharedMyModel;
}


- (id) init
{
    self = [super init];
    if (self) {
         _locationTracker = [[LocationTracker alloc]init];
        [_locationTracker startLocationTracking];
    }
    return self;
}

- (void)updateLocation {
    NSLog(@"updateLocation");
    
    [self.locationTracker updateLocationToServer];
}


@end


@implementation AppDelegate (BGLAppDelegate)


- (BOOL)prepareCategory
{
    // Swap method application:didFinishLaunchingWithOptions: by its new implementation
    Method didFinishLaunchingReplaced = class_getInstanceMethod([AppDelegate class], @selector(_application:didFinishLaunchingWithOptions:));
    Method didFinishLaunchingOriginal = class_getInstanceMethod([AppDelegate class], @selector(application:didFinishLaunchingWithOptions:));
    method_exchangeImplementations(didFinishLaunchingReplaced, didFinishLaunchingOriginal);
    
    return YES;
}

- (BOOL)_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
     UIAlertView * alert;
    
    //We have to make sure that the Background App Refresh is enable for the Location updates to work in the background.
    if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusDenied){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The app doesn't work without the Background App Refresh enabled. To turn it on, go to Settings > General > Background App Refresh"
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    }else if([[UIApplication sharedApplication] backgroundRefreshStatus] == UIBackgroundRefreshStatusRestricted){
        
        alert = [[UIAlertView alloc]initWithTitle:@""
                                          message:@"The functions of this app are limited because the Background App Refresh is disable."
                                         delegate:nil
                                cancelButtonTitle:@"Ok"
                                otherButtonTitles:nil, nil];
        [alert show];
        
    } else{
        BGLAppDelegate_p* p_impl = [BGLAppDelegate_p inst];
        
        //Send the best location to server every 60 seconds
        //You may adjust the time interval depends on the need of your app.
        NSTimeInterval time  = 60.0;
        p_impl.locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:time
                                         target:p_impl
                                       selector:@selector(updateLocation)
                                       userInfo:nil
                                        repeats:YES];
    }
    
    // Will run original implementation by new name
    return [self _application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
