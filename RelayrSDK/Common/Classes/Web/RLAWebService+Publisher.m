#import "RLAWebService+Publisher.h" // Header
#import "RLAWebService+Parsing.h"   // Relayr.framework (Web)

#import "RelayrUser.h"              // Relayr.framework (Public)
#import "RelayrPublisher.h"         // Relayr.framework (Public)
#import "RLAWebRequest.h"           // Relayr.framework (Web)
#import "RLAWebConstants.h"         // Relayr.framework (Web)
#import "RLAError.h"                // Relayr.framework (Utilities)

@implementation RLAWebService (Publisher)

#pragma mark - Public API

+ (void)requestAllRelayrPublishers:(void (^)(NSError* error, NSArray* publishers))completion
{
    if (!completion) { return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:[NSURL URLWithString:Web_Host]];
    if (!request) { return completion(RLAErrorMissingArgument, nil); }
    request.relativePath = Web_RequestRelativePath_Publishers;
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSArray* json = processRequest(Web_RequestResponseCode_Publishers, nil);
        
        NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:json.count];
        for (NSDictionary* dict in result)
        {
            RelayrPublisher* pub = [RLAWebService parsePublisherFromJSONDictionary:dict];
            if (pub) { [result addObject:pub]; }
        }
        
        return completion(nil, (result.count) ? [NSArray arrayWithArray:result] : nil);
    }];
}

- (void)registerPublisherWithName:(NSString*)publisherName ownerID:(NSString*)ownerID completion:(void (^)(NSError* error, RelayrPublisher* publisher))completion
{
    if (!publisherName.length || !ownerID.length) { if (completion) { completion(RLAErrorMissingArgument, nil); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { if (completion) { completion(RLAErrorWebrequestFailure, nil); } return; }
    request.relativePath = Web_RequestRelativePath_PublisherRegistration;
    request.body = @{ Web_RequestBodyKey_PublisherName : publisherName, Web_RequestBodyKey_PublisherOwner : ownerID };
    
    [request executeInHTTPMode:kRLAWebRequestModePOST completion:(!completion) ? nil : ^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_PublisherRegistration, nil);
        
        RelayrPublisher* result = [RLAWebService parsePublisherFromJSONDictionary:json];
        return (result) ? completion(nil, result) : completion(RLAErrorWebrequestFailure, nil);
    }];
}

- (void)setPublisher:(NSString*)publisherID withName:(NSString*)futurePublisherName completion:(void (^)(NSError* error))completion
{
    if (!publisherID.length || !futurePublisherName.length) { if (completion) { completion(RLAErrorMissingArgument); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { if (completion) { completion(RLAErrorWebrequestFailure); } return; }
    request.relativePath = Web_RequestRelativePath_PublisherSet(publisherID);
    
    [request executeInHTTPMode:kRLAWebRequestModePATCH completion:(!completion) ? nil : ^(NSError* error, NSNumber* responseCode, NSData* data) {
        if (error) { return completion(error); }
        if (responseCode.unsignedIntegerValue != Web_RequestResponseCode_PublisherSet || !data) { return completion(RLAErrorWebrequestFailure); }
        
        return completion(nil);
    }];
}

- (void)requestAppsFromPublisher:(NSString*)publisherID completion:(void (^)(NSError* error, NSArray* apps))completion
{
    if (!completion) { return; }
    if (!publisherID.length) { return completion(RLAErrorMissingArgument, nil); }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebrequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_PublishersApps(publisherID);
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError* error, NSNumber* responseCode, NSData* data) {
        NSArray* json = processRequest(Web_RequestResponseCode_PublishersApps, nil);
        
        NSMutableArray* result = [[NSMutableArray alloc] initWithCapacity:json.count];
        for (NSDictionary* dict in json)
        {
            RelayrApp* app = [RLAWebService parseAppFromJSONDictionary:dict];
            if (app) { [result addObject:app]; }
        }
        
        return completion(nil, (result.count) ? [NSArray arrayWithArray:result] : nil);
    }];
}

@end
