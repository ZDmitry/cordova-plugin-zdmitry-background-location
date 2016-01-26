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

@interface LocationTracker : NSObject <CLLocationManagerDelegate>

@property (nonatomic,retain) NSString*      serverUrl;
@property (nonatomic,retain) NSString*      serverToken;
@property (nonatomic,assign) NSTimeInterval serverInterval;

@property (nonatomic) CLLocationCoordinate2D myLastLocation;
@property (nonatomic) CLLocationAccuracy myLastLocationAccuracy;

@property (strong,nonatomic) LocationShareModel * shareModel;

@property (nonatomic) CLLocationCoordinate2D myLocation;
@property (nonatomic) CLLocationAccuracy myLocationAccuracy;

@property (nonatomic,assign) CLLocationAccuracy desiredAccuracy;
@property (nonatomic,assign) CLLocationDistance distanceFilter;


+ (CLLocationManager *)sharedLocationManager;

- (void)startLocationTracking;
- (void)stopLocationTracking;
- (void)updateLocationToServer;

- (void)sendData:(NSDictionary*)dict;


@end
