#import "BGLAppDelegate+BackgroundLocation.h"
#import "AppDelegate.h"

#import <Availability.h>
#import <objc/runtime.h>

#import "CDVBackgroundLocation.h"
#import "BGLLocationTracker.h"
#import "BGLNetworkManager.h"


@interface BGLAppDelegate_p : NSObject {
    BGLNetworkManager*     _logger;
    CDVBackgroundLocation* _cdvBackgroundLocation;
}

+ (id) sharendInst;

- (BOOL)startPoolingLocation;

@end

@implementation BGLAppDelegate_p

+ (id) sharendInst
{
    static id sharedInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[self alloc] init];
    });
    return sharedInst;
}

- (id) init
{
    self = [super init];
    if (self) {
        _logger = [[BGLNetworkManager alloc] init:@"" withToken:nil];
        _logger.useTimestamp = YES;
        
        _cdvBackgroundLocation = [[CDVBackgroundLocation alloc] init];
    }
    return self;
}

- (void)log:(NSDictionary*)dict
{
    if (_logger && dict && dict.count > 0) {
        [_logger sendDictionary:dict withCompletion:nil];
    }
}

- (BOOL)startPoolingLocation
{
    [_cdvBackgroundLocation configureWithDefaults];
    return YES;
}

@end


@implementation AppDelegate (BackgroundLocation)

/**
 * Its dangerous to override a method from within a category.
 * Instead we will use method swizzling.
 */
+ (void) load
{
    [self _bglExchangeMethods:@selector(application:didFinishLaunchingWithOptions:)
                     swizzled:@selector(_application:didFinishLaunchingWithOptions:)];
    
    [self _bglExchangeMethods:@selector(applicationWillTerminate:)
                     swizzled:@selector(_applicationWillTerminate:)];
}

- (BOOL)_application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    BGLAppDelegate_p* _pimpl = [BGLAppDelegate_p sharendInst];
    
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        [_pimpl log:@{ @"action": @"application:didFinishLaunchingWithOptions:", @"reason": @"UIApplicationLaunchOptionsLocationKey" }];
        [_pimpl startPoolingLocation];
    }

    // [self startPoolingLocation];
    
    // Will run original implementation by new name
    return [self _application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)_applicationWillTerminate:(UIApplication *)application
{
    [[BGLAppDelegate_p sharendInst] log:@{ @"action": @"applicationWillTerminate:" }];
    
    // Will run original implementation by new name
    [self _applicationWillTerminate:application];
}

#pragma mark -
#pragma mark Swizzling

void _bglDefaultMethodIMP (id self, SEL _cmd) { /* nothing to do here */ }

/**
 * Exchange the method implementations.
 */
+ (void) _bglExchangeMethods:(SEL)original swizzled:(SEL)swizzled
{
    class_addMethod(self, original, (IMP)_bglDefaultMethodIMP, "v@:");

    Method original_method = class_getInstanceMethod(self, original);
    Method swizzled_method = class_getInstanceMethod(self, swizzled);

    if ( original_method != swizzled_method ) {
        method_exchangeImplementations(original_method, swizzled_method);
    }
}

@end
