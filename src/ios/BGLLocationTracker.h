//
//  LocationTracker.h
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BGLLocationShareModel.h"


#define kCDVBackgroundLocation_stationaryRadius  @"CDVBackgroundLocation.stationaryRadius"
#define kCDVBackgroundLocation_distanceFilter    @"CDVBackgroundLocation.distanceFilter"
#define kCDVBackgroundLocation_locationTimeout   @"CDVBackgroundLocation.locationTimeout"
#define kCDVBackgroundLocation_desiredAccuracy   @"CDVBackgroundLocation.desiredAccuracy"
#define kCDVBackgroundLocation_isDebugging       @"CDVBackgroundLocation.isDebugging"
#define kCDVBackgroundLocation_stopOnTerminate   @"CDVBackgroundLocation.stopOnTerminate"
#define kCDVBackgroundLocation_interval          @"CDVBackgroundLocation.interval"
    
#define kCDVBackgroundLocation_serverUrl         @"CDVBackgroundLocation.serverUrl"
#define kCDVBackgroundLocation_authToken         @"CDVBackgroundLocation.authToken"

// Minimal pool interval in seconds
#define MIN_POOL_INTERVAL  15


@interface LocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic,assign) NSTimeInterval serverInterval;
@property (nonatomic,assign) BOOL           serverEnabled;

@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;

@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic,assign) CLLocationDistance distanceFilter;


+ (CLLocationManager *)sharedLocationManager;
+ (CLLocationAccuracy)decodeDesiredAccuracy:(long)accuracy;

- (void)startLocationTracking;
- (void)stopLocationTracking;
- (void)updateLocationToServer;

@end
