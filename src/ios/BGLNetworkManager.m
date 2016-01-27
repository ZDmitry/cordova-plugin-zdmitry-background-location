#import "BGLNetworkManager.h"


@implementation BGLNetworkManager

+ (id) sharedInstance
{
    static id sharedInst = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInst = [[self alloc] init];
    });
    return sharedInst;
}

- (id)init {
    if (self = [super init]) {
        _serverUrl   = @"";
        _serverToken = nil;
    }
    return self;
}

- (id) init:(NSString*)serverURL withToken:(NSString*)token
{
    if (self = [super init]) {
        _serverUrl   = (serverURL ? serverURL : @"");
        _serverToken = token;
    }
    return self;
}

- (NSString*) datetimeISONow
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    return [formatter stringFromDate:[NSDate date]];
}

- (void) sendString:(NSString*)text withCompletion:(BGLDownloadComplete_block)block
{
    NSString* data = (text ? text : @"");
    
    [self sendData:[data dataUsingEncoding:NSUTF8StringEncoding]
      withMimeType:@"text/plain"
    withCompletion:block];
}

- (void) sendDictionary:(NSDictionary*)dict withCompletion:(BGLDownloadComplete_block)block
{
    NSError*  error      = nil;
    NSString* jsonString = @"{ }";
    
    NSData*   jsonData   = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    if (jsonData && !error) {
        jsonString = [[NSString alloc] initWithBytes:[jsonData bytes] length:[jsonData length] encoding:NSUTF8StringEncoding];
    }
    
    [self sendData:[jsonString dataUsingEncoding:NSUTF8StringEncoding]
      withMimeType:@"application/json"
    withCompletion:block];
}

- (void) sendData:(NSData*)data withMimeType:(NSString*)mimeType withCompletion:(BGLDownloadComplete_block)block
{
    if (data && data.length > 0) {
        // OK
    } else {
        if (block) {
            NSDictionary* errDict = @{
                NSLocalizedDescriptionKey:             NSLocalizedString(@"Data should be provided and have non zero length in bytes.", nil),
                NSLocalizedFailureReasonErrorKey:      NSLocalizedString(@"No data provided.", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Data should be provided and have non zero length in bytes.", nil)
            };
            
            NSError* error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorCannotDecodeRawData
                                             userInfo:errDict];
            block(nil, nil, error);
            return;
        }
    }
    
    if ([_serverUrl hasPrefix:@"http://"] || [_serverUrl hasPrefix:@"https://"]) {
        // OK
    } else {
        if (block) {
            NSDictionary* errDict = @{
                NSLocalizedDescriptionKey:             NSLocalizedString(@"Url address should start with http:// or https://", nil),
                NSLocalizedFailureReasonErrorKey:      NSLocalizedString(@"Bad url address was provided.", nil),
                NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Url address should start with http:// or https://", nil)
            };
            
            NSError* error = [NSError errorWithDomain:NSURLErrorDomain
                                                 code:NSURLErrorBadURL
                                             userInfo:errDict];
            block(nil, nil, error);
            return;
        }
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:_serverUrl]];
        
    [request setHTTPMethod:@"POST"];
    [request setValue:mimeType forHTTPHeaderField:@"Content-type"];
    
    if (_serverToken && _serverToken.length > 0) {
        [request setValue:_serverToken forHTTPHeaderField:@"Authorization"];
    }
    [request setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[data length]] forHTTPHeaderField:@"Content-length"];
    [request setHTTPBody:data];
    
    NSURLSession*         session  = [NSURLSession sharedSession];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request completionHandler:block];
    [dataTask resume];
}

@end