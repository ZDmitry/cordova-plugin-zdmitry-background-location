#import "CDVBackgroundLocation.h"
#import <Cordova/CDVJSON.h>

#import "BGLAppDelegate+BackgroundLocation.h"
#import "BGLLocationTracker.h"
#import "BGLBackgroundTaskManager.h"

#import <CoreLocation/CoreLocation.h>

// Minimal pool interval in seconds
#define MIN_POOL_INTERVAL  15


@implementation CDVBackgroundLocation {
    BOOL  _enabled;
    BOOL  _isDebugging;
    BOOL  _stopOnTerminate;
    
    long  _distanceFilter;
    long  _locationTimeout;
    long  _stationaryRadius;
    long  _desiredAccuracy;
    long  _interval;
    
    /* LocationTracker */
    LocationTracker*  _locationTracker;
    NSTimer*          _locationUpdateTimer;
}

- (void)pluginInitialize
{
    // background location cache, for when no network is detected.
    _locationTracker  = [[LocationTracker alloc] init];

    _isDebugging     = NO;
    _stopOnTerminate = NO;
}

- (void) configure:(CDVInvokedUrlCommand*)command
{
    // Params.

    //    0                    1               2                 3           4          5             6        7         8
    //[stationaryRadius, distanceFilter, locationTimeout, desiredAccuracy, debug, stopOnTerminate, interval, server, authToken]

    // UNUSED ANDROID VARS
    _stationaryRadius    = [[command.arguments objectAtIndex: 0] intValue];
    _distanceFilter      = [[command.arguments objectAtIndex: 1] intValue];
    _locationTimeout     = [[command.arguments objectAtIndex: 2] intValue];
    _desiredAccuracy     = [[command.arguments objectAtIndex: 3] intValue];
    _isDebugging         = [[command.arguments objectAtIndex: 4] boolValue];
    _stopOnTerminate     = [[command.arguments objectAtIndex: 5] boolValue];
    _interval            = [[command.arguments objectAtIndex: 6] intValue];
    
    NSString* serverUrl  = [command.arguments objectAtIndex: 7];
    NSString* authToken  = [command.arguments objectAtIndex: 8];
    
    _locationTracker.serverUrl      = serverUrl;
    _locationTracker.serverToken    = authToken;
    
    if (_interval > MIN_POOL_INTERVAL) {
        _locationTracker.serverInterval = _interval;
    }
    
    _locationTracker.desiredAccuracy = [self decodeDesiredAccuracy:_desiredAccuracy];
    _locationTracker.distanceFilter  = (_distanceFilter < (-1) ? kCLDistanceFilterNone : _distanceFilter);

    NSLog(@"CDVBackgroundLocation configure");
    NSLog(@"  - distanceFilter: %ld", _distanceFilter);
    NSLog(@"  - stationaryRadius: %ld", _stationaryRadius);
    NSLog(@"  - locationTimeout: %ld", _locationTimeout);
    NSLog(@"  - desiredAccuracy: %ld", _desiredAccuracy);
    NSLog(@"  - debug: %d", _isDebugging);
    NSLog(@"  - stopOnTerminate: %d", _stopOnTerminate);
    NSLog(@"  - interval: %ld", _interval);
    
    NSLog(@"  - server: %@", serverUrl);
}

- (void) start:(CDVInvokedUrlCommand*)command;
{
    [_locationTracker startLocationTracking];
    
    //Send the best location to server every 60 seconds
    //You may adjust the time interval depends on the need of your app.
    NSTimeInterval time  = _locationTracker.serverInterval;
    _locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:time
                                     target:self
                                   selector:@selector(updateLocation)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) stop:(CDVInvokedUrlCommand*)command
{
    BackgroundTaskManager* taskMan = [BackgroundTaskManager sharedBackgroundTaskManager];
    [taskMan endAllBackgroundTasks];
    
    [_locationTracker stopLocationTracking];
    [_locationUpdateTimer invalidate];
     _locationUpdateTimer = nil;
}

-(CLLocationAccuracy)decodeDesiredAccuracy:(long)accuracy
{
    CLLocationAccuracy locationAccuracy;
    
    switch (accuracy) {
        case 1000:
            locationAccuracy = kCLLocationAccuracyKilometer;
            break;
        case 100:
            locationAccuracy = kCLLocationAccuracyHundredMeters;
            break;
        case 10:
            locationAccuracy = kCLLocationAccuracyNearestTenMeters;
            break;
        case 0:
            locationAccuracy = kCLLocationAccuracyBest;
            break;
        default:
            locationAccuracy = kCLLocationAccuracyHundredMeters;
    }
    
    return locationAccuracy;
}

- (void)updateLocation {
    NSLog(@"updateLocation");
    
    [_locationTracker updateLocationToServer];
}


@end