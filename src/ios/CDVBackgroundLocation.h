#import <Cordova/CDVPlugin.h>


@interface CDVBackgroundLocation : CDVPlugin

- (void) configureWithDefaults;
- (void) configure:(CDVInvokedUrlCommand*)command;

- (void) start:(CDVInvokedUrlCommand*)command;
- (void) stop:(CDVInvokedUrlCommand*)command;

@end

