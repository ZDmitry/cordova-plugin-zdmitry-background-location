//
//  LocationTracker.m
//  Location
//
//  Created by Rick
//  Copyright (c) 2014 Location All rights reserved.
//

#import "BGLLocationTracker.h"
#import "BGLNetworkManager.h"

#define LATITUDE  @"latitude"
#define LONGITUDE @"longitude"
#define ACCURACY  @"accuracy"

// Pool interval in seconds
#define DEFAULT_POOL_INTERVAL  15

#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)


@interface LocationTracker () <BackgroundTaskManagerDelegate> {
    NSDate*          _lastReportDate;
    NSMutableArray*  _defferedRequests;
}

@end


@implementation LocationTracker

+ (CLLocationManager *)sharedLocationManager {
    static CLLocationManager *_locationManager;
    
    @synchronized(self) {
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
            _locationManager.pausesLocationUpdatesAutomatically = NO;
            _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
            _locationManager.distanceFilter  = kCLDistanceFilterNone;
            
#ifdef __IPHONE_9_0
            if ([_locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
                _locationManager.allowsBackgroundLocationUpdates = YES;
            }
#endif
        }
    }
    return _locationManager;
}

+(CLLocationAccuracy)decodeDesiredAccuracy:(long)accuracy
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

- (id)init {
    if (self==[super init]) {
        //Get the share model and also initialize myLocationArray
        self.shareModel = [LocationShareModel sharedModel];
        self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
        
        _lastReportDate = nil;
        _serverInterval = DEFAULT_POOL_INTERVAL;
        _serverEnabled  = YES;
        
        _defferedRequests = [[NSMutableArray alloc] init];
        
        [BackgroundTaskManager sharedBackgroundTaskManager].delegate = self;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void) setDesiredAccuracy:(CLLocationAccuracy)accuracy
{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.desiredAccuracy = accuracy;
}

- (CLLocationAccuracy) desiredAccuracy
{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    return locationManager.desiredAccuracy;
}

- (void) setDistanceFilter:(CLLocationDistance)distance
{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.distanceFilter = distance;
}

- (CLLocationDistance) distanceFilter
{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    return locationManager.distanceFilter;
}

-(void)applicationEnterBackground{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    [locationManager startUpdatingLocation];
    [locationManager startMonitoringSignificantLocationChanges];
    
    //Use the BackgroundTaskManager to manage all the background Task
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
}

- (void) restartLocationUpdates
{
    NSLog(@"restartLocationUpdates");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    locationManager.delegate = self;
    
    if(IS_OS_8_OR_LATER) {
        [locationManager requestAlwaysAuthorization];
    }
    
    [locationManager startUpdatingLocation];
    [locationManager startMonitoringSignificantLocationChanges];
}


- (void)startLocationTracking {
    NSLog(@"startLocationTracking");

    if ([CLLocationManager locationServicesEnabled] == NO) {
        NSLog(@"locationServicesEnabled false");
        UIAlertView *servicesDisabledAlert = [[UIAlertView alloc] initWithTitle:@"Location Services Disabled" message:@"You currently have all location services for this device disabled" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [servicesDisabledAlert show];
    } else {
        CLAuthorizationStatus authorizationStatus= [CLLocationManager authorizationStatus];
        
        if(authorizationStatus == kCLAuthorizationStatusDenied || authorizationStatus == kCLAuthorizationStatusRestricted){
            NSLog(@"authorizationStatus failed");
        } else {
            NSLog(@"authorizationStatus authorized");
            CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
            locationManager.delegate = self;
            
            if(IS_OS_8_OR_LATER) {
              [locationManager requestAlwaysAuthorization];
            }
            
            [locationManager startUpdatingLocation];
            [locationManager startMonitoringSignificantLocationChanges];
        }
    }
}


- (void)stopLocationTracking {
    NSLog(@"stopLocationTracking");
    
    if (self.shareModel.timer) {
        [self.shareModel.timer invalidate];
        self.shareModel.timer = nil;
    }
    
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    
    NSLog(@"locationManager didUpdateLocations");
    
    /* for( int i=0; i<locations.count; i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        [self sendData:[self locationToHash:newLocation]];
    }
    
    return; */
    
    for(int i=0;i<locations.count;i++){
        CLLocation * newLocation = [locations objectAtIndex:i];
        CLLocationCoordinate2D theLocation = newLocation.coordinate;
        CLLocationAccuracy theAccuracy = newLocation.horizontalAccuracy;
        
        NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
        
        if (locationAge > 30.0) continue;
        
        //Select only valid location and also location with good accuracy
        if( newLocation != nil ) {
            NSMutableDictionary* dict = [self locationToHash:newLocation];
            if (theAccuracy > 0 && theAccuracy < 2000 && (!(theLocation.latitude == 0.f && theLocation.longitude == 0.f))) {
                self.myLastLocation = theLocation;
                self.myLastLocationAccuracy= theAccuracy;
                
                //Add the vallid location with good accuracy into an array
                //Every 1 minute, I will select the best location based on accuracy and send to server
                [self.shareModel.myLocationArray addObject:dict];
            } else {
                NSLog(@"Bad location: %@", dict);
            }
        }
    }
    
    //If the timer still valid, return it (Will not run the code below)
    if (self.shareModel.timer) {
        NSTimeInterval timeInterval = [[self.shareModel.timer fireDate] timeIntervalSinceNow];
        NSLog(@"Timer is valid... Will wait = %.4f", timeInterval);
        return;
    }
    
    self.shareModel.bgTask = [BackgroundTaskManager sharedBackgroundTaskManager];
    [self.shareModel.bgTask beginNewBackgroundTask];
    
    //Restart the locationMaanger after 1 minute
    self.shareModel.timer = [NSTimer scheduledTimerWithTimeInterval:_serverInterval target:self
                                                           selector:@selector(restartLocationUpdates)
                                                           userInfo:nil
                                                            repeats:NO];
    
    //Will only stop the locationManager after 10 seconds, so that we can get some accurate locations
    //The location manager will only operate for 10 seconds to save battery
    if (self.shareModel.delay10Seconds) {
        [self.shareModel.delay10Seconds invalidate];
        self.shareModel.delay10Seconds = nil;
    }
    
    self.shareModel.delay10Seconds = [NSTimer scheduledTimerWithTimeInterval:10 target:self
                                                    selector:@selector(stopLocationDelayBy10Seconds)
                                                    userInfo:nil
                                                     repeats:NO];

}


//Stop the locationManager
-(void)stopLocationDelayBy10Seconds{
    CLLocationManager *locationManager = [LocationTracker sharedLocationManager];
    [locationManager stopUpdatingLocation];
    
    NSLog(@"locationManager stop Updating after 10 seconds");
}


- (void)locationManager: (CLLocationManager *)manager didFailWithError: (NSError *)error
{
   // NSLog(@"locationManager error:%@",error);
    
    switch([error code])
    {
        case kCLErrorNetwork: // general, network-related error
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Error" message:@"Please check your network connection." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        case kCLErrorDenied:{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Enable Location Service" message:@"You have to enable the Location Service to use this App. To enable, please go to Settings->Privacy->Location Services" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
            [alert show];
        }
            break;
        default:
        {
            
        }
            break;
    }
}


//Send the location to Server
- (void)updateLocationToServer {
    
    NSLog(@"updateLocationToServer");
    
    // Find the best location from the array based on accuracy
    NSMutableDictionary * myBestLocation = [[NSMutableDictionary alloc]init];
    
    for(int i=0;i<self.shareModel.myLocationArray.count;i++){
        NSMutableDictionary * currentLocation = [self.shareModel.myLocationArray objectAtIndex:i];
        
        if(i==0)
            myBestLocation = currentLocation;
        else{
            if([[currentLocation objectForKey:ACCURACY]floatValue]<=[[myBestLocation objectForKey:ACCURACY]floatValue]){
                myBestLocation = currentLocation;
            }
        }
    }
    NSLog(@"My Best location:%@",myBestLocation);
    
    //If the array is 0, get the last location
    //Sometimes due to network issue or unknown reason, you could not get the location during that  period, the best you can do is sending the last known location to the server
    if(self.shareModel.myLocationArray.count==0)
    {
        NSLog(@"Unable to get location, use the last known location");

        self.myLocation=self.myLastLocation;
        self.myLocationAccuracy=self.myLastLocationAccuracy;
        
    }else{
        CLLocationCoordinate2D theBestLocation;
        theBestLocation.latitude =[[myBestLocation objectForKey:LATITUDE]floatValue];
        theBestLocation.longitude =[[myBestLocation objectForKey:LONGITUDE]floatValue];
        self.myLocation=theBestLocation;
        self.myLocationAccuracy =[[myBestLocation objectForKey:ACCURACY]floatValue];
    }
    
    NSLog(@"Send to Server: Latitude(%f) Longitude(%f) Accuracy(%f)",self.myLocation.latitude, self.myLocation.longitude,self.myLocationAccuracy);
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSString* timestamp = [formatter stringFromDate:[NSDate date]];
    
    NSDictionary *dict = @{
        @"lat": @(self.myLocation.latitude),
        @"lng": @(self.myLocation.longitude),
        @"createdAt": timestamp
    };
    
    if (_serverEnabled) { //Send data to your server
        [[BGLNetworkManager sharedInstance] sendDictionary:myBestLocation withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (error) { // error.domain == NSURLErrorDomain && error.code == NSURLErrorNotConnectedToInternet) {
                [_defferedRequests addObject:myBestLocation];
            } else {
                if (_defferedRequests.count > 0) {
                    [self sendDefferedData];
                }
            }
            
        }];
    }
    
    //After sending the location to the server successful, remember to clear the current array with the following code.
    //It is to make sure that you clear up old location in the array and add the new locations from locationManager
    [self.shareModel.myLocationArray removeAllObjects];
    self.shareModel.myLocationArray = nil;
    self.shareModel.myLocationArray = [[NSMutableArray alloc]init];
}

-(NSMutableDictionary*) locationToHash:(CLLocation*)location
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    NSString* timestamp = [formatter stringFromDate:location.timestamp];
    
    NSDictionary* locationDict = @{
        @"timestamp":        timestamp,
        @"speed":            @(location.speed),
        @"altitudeAccuracy": @(location.verticalAccuracy),
        @"accuracy":         @(location.horizontalAccuracy),
        @"heading":          @(location.course),
        @"altitude":         @(location.altitude),
        @"latitude":         @(location.coordinate.latitude),
        @"longitude":        @(location.coordinate.longitude)
    };
    
    // NSDictionary* returnInfo = @{
    //     @"lat": @(location.coordinate.latitude),
    //     @"lng": @(location.coordinate.longitude),
    //     @"createdAt": timestamp
    // };
    
    return [locationDict mutableCopy];
}

- (void) sendDefferedData
{
    if (![_defferedRequests count]) {
        return;
    }
    
    BGLNetworkManager* logger   = [[BGLNetworkManager alloc] init:@"" withToken:nil];
    
    NSDictionary* locationBulk = @{@"coordinates": _defferedRequests};
    
    NSURLSessionDataTask* task = [[BGLNetworkManager sharedInstance] defferedSendDictionary:locationBulk withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (data && !error) {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
            NSString* timeNow = [formatter stringFromDate:[NSDate date]];
            
            NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
            long statusCode = (httpResp ? httpResp.statusCode : (-1));
            
            NSString* respData = @"";
            if (data && data.length > 0 && data.bytes ) {
                respData = [NSString stringWithUTF8String:data.bytes];
            }
            
            
            [_defferedRequests removeAllObjects];
        }
    }];
    if (task) {
        [task resume];
    };
    
}

#pragma mark -
#pragma mark BackgroundTaskManagerDelegate

- (void) backgroundTaskExpired:(unsigned long)taskId
{
    [[BGLNetworkManager sharedInstance]
        sendDictionary:@{
            @"event":  @"backgroundTaskExpired",
            @"return": @(taskId)
        }
        withCompletion:^(NSData *data, NSURLResponse *response, NSError *error) {
        // ...
    }];
}

@end
