#import "BGLAppDelegate+BackgroundLocation.h"
#import "BGLLocationTracker.h"
#import "BGLNetworkManager.h"


@interface BGLAppDelegate () {
    LocationTracker*  _locationTracker;
    NSTimer*          _locationUpdateTimer;
}

- (void)updateLocation;

@end


@implementation BGLAppDelegate

- (id) init
{
    self = [super init];
    if (self) {
         _locationTracker = nil; // [[LocationTracker alloc] init];
        // [_locationTracker startLocationTracking];
         _locationUpdateTimer = nil;
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BGLNetworkManager* networkManager = [BGLNetworkManager sharedInstance];
    [networkManager sendDictionary:@{ @"launch_options": (launchOptions ? launchOptions : @"{ }") } withCompletion:nil];

    // [self startPoolingLocation];
    
    // Will run original implementation by new name
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[BGLNetworkManager sharedInstance] sendDictionary:@{ @"signal": @"applicationWillTerminate" } withCompletion:nil];
    
    [super applicationWillTerminate:application];
}

- (BOOL)startPoolingLocation
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
        
    } else {
        if (_locationTracker == nil) {
            _locationTracker = [[LocationTracker alloc] init];
           [_locationTracker startLocationTracking];
        }
        //Send the best location to server every 60 seconds
        //You may adjust the time interval depends on the need of your app.
        NSTimeInterval time  = 60.0;
        _locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:time
                                         target:self
                                       selector:@selector(updateLocation)
                                       userInfo:nil
                                        repeats:YES];
        
        return YES;
    }
    
    return NO;
}

- (void)updateLocation {
    NSLog(@"updateLocation");
    
    [_locationTracker updateLocationToServer];
}

- (BOOL)stopPoolingLocation
{
    [_locationUpdateTimer invalidate];
     _locationUpdateTimer = nil;
    
    return YES;
}

@end
