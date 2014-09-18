#import "RLAWebService+Device.h"    // Header
#import "RLAWebService+Parsing.h"   // Relayr.framework (Web)

#import "RelayrUser.h"              // Relayr.framework (Public)
#import "RelayrDeviceModel.h"       // Relayr.framework (Public)
#import "RLAWebRequest.h"           // Relayr.framework (Web)
#import "RLAWebConstants.h"         // Relayr.framework (Web)
#import "RLAError.h"                // Relayr.framework (Utilities)

@implementation RLAWebService (Device)

- (void)registerDeviceWithName:(NSString*)deviceName owner:(NSString*)ownerID model:(NSString*)modelID firmwareVersion:(NSString*)firmwareVersion completion:(void (^)(NSError* error, RelayrDevice* device))completion
{
    if (!deviceName.length || !ownerID.length || !modelID.length || !firmwareVersion.length) { if (completion) { completion(RLAErrorMissingArgument, nil); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { if (completion) { completion(RLAErrorWebRequestFailure, nil); } return; }
    request.relativePath = Web_RequestRelativePath_DevRegistration;
    request.body = @{ Web_RequestBodyKey_DevName : deviceName, Web_RequestBodyKey_DevOwner : ownerID, Web_RequestBodyKey_DevModel : modelID, Web_RequestBodyKey_DevFirmwareVersion : firmwareVersion };
    
    [request executeInHTTPMode:kRLAWebRequestModePOST completion:(!completion) ? nil : ^(NSError* error, NSNumber* responseCode, NSData* data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_DevRegistration, nil);
        
        RelayrDevice* result = [RLAWebService parseDeviceFromJSONDictionary:json];
        return (!result) ? completion(RLAErrorRequestParsingFailure, nil) : completion(nil, result);
    }];
}

- (void)requestDevice:(NSString*)deviceID completion:(void (^)(NSError* error, RelayrDevice* device))completion
{
    if (!completion) { return; }
    if (!deviceID.length) { return completion(RLAErrorMissingArgument, nil); }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevInfo(deviceID);
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError* error, NSNumber* responseCode, NSData* data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_DevInfo, nil);
        
        RelayrDevice* result = [RLAWebService parseDeviceFromJSONDictionary:json];
        return (!result) ? completion(RLAErrorRequestParsingFailure, nil) : completion(nil, result);
    }];
}

- (void)setDevice:(NSString*)deviceID name:(NSString*)deviceName modelID:(NSString*)futureModelID isPublic:(NSNumber*)isPublic description:(NSString*)description completion:(void (^)(NSError* error, RelayrDevice* device))completion
{
    if (!deviceID.length) { if (completion) { completion(RLAErrorMissingArgument, nil); } return; }
    
    NSMutableDictionary* tmpDict = [[NSMutableDictionary alloc] init];
    if (deviceName.length) { tmpDict[Web_RequestBodyKey_DevName] = deviceName; }
    if (description.length) { tmpDict[Web_RequestBodyKey_DevDescription] = description; }
    if (futureModelID.length) { tmpDict[Web_RequestBodyKey_DevModel] = futureModelID; }
    if (isPublic) { tmpDict[Web_RequestBodyKey_DevPublic] = isPublic; }
    if (!tmpDict.count) { if (completion) { completion(RLAErrorMissingArgument, nil); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { if (completion) { completion(RLAErrorWebRequestFailure, nil); } return; }
    request.relativePath = Web_RequestRelativePath_DevInfoSet(deviceID);
    request.body = [NSDictionary dictionaryWithDictionary:tmpDict];
    
    [request executeInHTTPMode:kRLAWebRequestModePATCH completion:(!completion) ? nil : ^(NSError* error, NSNumber* responseCode, NSData* data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_DevInfoSet, nil);
        
        RelayrDevice* result = [RLAWebService parseDeviceFromJSONDictionary:json];
        return (!result) ? completion(RLAErrorRequestParsingFailure, nil) : completion(nil, result);
    }];
}

- (void)deleteDevice:(NSString*)deviceID completion:(void (^)(NSError* error))completion
{
    if (!deviceID.length) { if (completion) { completion(RLAErrorMissingArgument); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { if (completion) { completion(RLAErrorWebRequestFailure); } return; }
    request.relativePath = Web_RequestRelativePath_DevDelete(deviceID);
    
    [request executeInHTTPMode:kRLAWebRequestModeDELETE completion:(!completion) ? nil : ^(NSError* error, NSNumber* responseCode, NSData* data) {
        if (error) { return completion(error); }
        return (responseCode.unsignedIntegerValue != Web_RequestResponseCode_DevDelete) ? completion(RLAErrorWebRequestFailure) : completion(nil);
    }];
}

- (void)setConnectionBetweenDevice:(NSString*)deviceID andApp:(NSString*)appID completion:(void (^)(NSError* error, id credentials))completion
{
    if (!completion) { return; }
    if (!deviceID.length || !appID.length) { return completion(RLAErrorMissingArgument, nil); }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevConnection(deviceID, appID);
    
    [request executeInHTTPMode:kRLAWebRequestModePOST completion:^(NSError* error, NSNumber* responseCode, NSData* data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_DevConnection, nil);
        return completion(nil, json);
    }];
}

- (void)requestAppsConnectedToDevice:(NSString*)deviceID completion:(void (^)(NSError* error, NSArray* apps))completion
{
    if (!completion) { return; }
    if (!deviceID.length) { return completion(RLAErrorMissingArgument, nil); }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevConnected(deviceID);
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSArray* json = processRequest(Web_RequestResponseCode_DevConnected, nil);
        
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:json.count];
        for (NSDictionary* dict in json)
        {
            RelayrApp* dev = [RLAWebService parseAppFromJSONDictionary:dict];
            if (dev) { [result addObject:dev]; }
        }
        
        return completion(nil, (result.count) ? [NSArray arrayWithArray:result] : nil);
    }];
}

- (void)deleteConnectionBetweenDevice:(NSString*)deviceID andApp:(NSString*)appID completion:(void (^)(NSError* error))completion
{
    if (!deviceID.length || !appID.length) { if (completion) { completion(RLAErrorMissingArgument); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { if (completion) { completion(RLAErrorWebRequestFailure); } return; }
    request.relativePath = Web_RequestRelativePath_DevDisconnect(deviceID, appID);
    
    [request executeInHTTPMode:kRLAWebRequestModeDELETE completion:(!completion) ? nil : ^(NSError *error, NSNumber *responseCode, NSData *data) {
        if (error) { return completion(error); }
        return (responseCode.unsignedIntegerValue != Web_RequestResponseCode_DevDisconnect) ? completion(RLAErrorWebRequestFailure) : completion(nil);
    }];
}

- (void)requestPublicDevices:(void (^)(NSError* error, NSArray* devices))completion
{
    if (!completion) { return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevPublic;
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSArray* json = processRequest(Web_RequestResponseCode_DevPublic, nil);
        
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:json.count];
        for (NSDictionary* dict in json)
        {
            RelayrDevice* dev = [RLAWebService parseDeviceFromJSONDictionary:dict];
            if (dev) { [result addObject:dev]; }
        }
        
        return completion(nil, (result.count) ? [NSArray arrayWithArray:result] : nil);
    }];
}

- (void)requestPublicDevicesFilteredByMeaning:(NSString*)meaning completion:(void (^)(NSError* error, NSArray* devices))completion
{
    if (!meaning) { return [self requestPublicDevices:completion]; }
    if (!completion) { return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevPublicMeaning(meaning);
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSArray* json = processRequest(Web_RequestResponseCode_DevPublic, nil);
        
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:json.count];
        for (NSDictionary* dict in json)
        {
            RelayrDevice* dev = [RLAWebService parseDeviceFromJSONDictionary:dict];
            if (dev) { [result addObject:dev]; }
        }
        
        return completion(nil, (result.count) ? [NSArray arrayWithArray:result] : nil);
    }];
}

+ (void)setConnectionToPublicDevice:(NSString*)deviceID completion:(void (^)(NSError* error, id credentials))completion
{
    if (!deviceID.length) { if (completion) { completion(RLAErrorMissingArgument, nil); } return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:[NSURL URLWithString:Web_Host]];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevPublicSubcription(deviceID);
    
    [request executeInHTTPMode:kRLAWebRequestModePOST completion:(!completion) ? nil : ^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_DevPublicSubcription, nil);
        return completion(nil, json);
    }];
}

- (void)requestAllDeviceModels:(void (^)(NSError* error, NSArray* deviceModels))completion
{
    if (!completion) { return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevModel;
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSArray* json = processRequest(Web_RequestResponseCode_DevModel, nil);
        
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:json.count];
        for (NSDictionary* dict in json)
        {
            RelayrDeviceModel* devModel = [RLAWebService parseDeviceModelFromJSONDictionary:dict inDeviceObject:nil];
            if (devModel) { [result addObject:devModel]; }
        }
        
        return completion(nil, (result.count) ? [NSArray arrayWithArray:result] : nil);
    }];
}

- (void)requestDeviceModel:(NSString*)deviceModelID completion:(void (^)(NSError* error, RelayrDeviceModel* deviceModel))completion
{
    if (!completion) { return; }
    if (!deviceModelID) { return completion(RLAErrorMissingArgument, nil); }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevModelID(deviceModelID);
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSDictionary* json = processRequest(Web_RequestResponseCode_DevModelID, nil);
        
        RelayrDeviceModel* devModel = [RLAWebService parseDeviceModelFromJSONDictionary:json inDeviceObject:nil];
        return (!deviceModelID) ? completion(RLAErrorRequestParsingFailure, nil) : completion(nil, devModel);
    }];
}

- (void)requestAllDeviceMeanings:(void (^)(NSError* error, NSDictionary* meanings))completion
{
    if (!completion) { return; }
    
    RLAWebRequest* request = [[RLAWebRequest alloc] initWithHostURL:self.hostURL timeout:nil oauthToken:self.user.token];
    if (!request) { return completion(RLAErrorWebRequestFailure, nil); }
    request.relativePath = Web_RequestRelativePath_DevModelMeanings;
    
    [request executeInHTTPMode:kRLAWebRequestModeGET completion:^(NSError *error, NSNumber *responseCode, NSData *data) {
        NSArray* json = processRequest(Web_RequestResponseCode_DevModelMeanings, nil);
        
        NSMutableDictionary* result = [NSMutableDictionary dictionaryWithCapacity:json.count];
        for (NSDictionary* dict in json)
        {
            NSString* key = dict[Web_RespondKey_DeviceModelKey];
            NSString* value = dict[Web_RespondKey_DeviceModelValue];
            if (key && value) { result[key] = value; }
        }
        
        return completion(nil, (result.count) ? [NSDictionary dictionaryWithDictionary:result] : nil);
    }];
}

@end