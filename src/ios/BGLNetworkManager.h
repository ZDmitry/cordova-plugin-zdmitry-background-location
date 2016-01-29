#import <Foundation/Foundation.h>


typedef void (^BGLDownloadComplete_block)(NSData* data, NSURLResponse* response, NSError* error);


@interface BGLNetworkManager : NSObject

@property (nonatomic,retain) NSString*  serverUrl;
@property (nonatomic,retain) NSString*  serverToken;
@property (nonatomic,assign) BOOL       useTimestamp;

+ (id) sharedInstance;

- (id) init:(NSString*)serverURL withToken:(NSString*)token;

- (void) sendString:(NSString*)text withCompletion:(BGLDownloadComplete_block)block;
- (void) sendDictionary:(NSDictionary*)text withCompletion:(BGLDownloadComplete_block)block;
- (void) sendURLEncoded:(NSDictionary*)text withCompletion:(BGLDownloadComplete_block)block;
- (void) sendData:(NSData*)data withMimeType:(NSString*)mimeType withCompletion:(BGLDownloadComplete_block)block;

- (NSURLSessionDataTask*) defferedSendString:(NSString*)text withCompletion:(BGLDownloadComplete_block)block;
- (NSURLSessionDataTask*) defferedSendDictionary:(NSDictionary*)text withCompletion:(BGLDownloadComplete_block)block;
- (NSURLSessionDataTask*) defferedSendURLEncoded:(NSDictionary*)text withCompletion:(BGLDownloadComplete_block)block;
- (NSURLSessionDataTask*) defferedSendData:(NSData*)data withMimeType:(NSString*)mimeType withCompletion:(BGLDownloadComplete_block)block;

@end
