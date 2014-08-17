#import "RLASensorValue.h"          // Header
#import "RLASensorValue_Setup.h"    // Extension

@implementation RLASensorValue

#pragma mark - Public API

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (NSDate*)timestamp
{
    NSNumber* timestamp = [_dictionary objectForKey:@"ts"];
    return [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue];
}

#pragma mark NSCopying

#warning WTF
//- (instancetype)copyWithZone:(NSZone *)zone
//{
//    typeof(self) copy = [[[self class] alloc] initWithDictionary:self.RLA_dictionary];
//    return copy;
//    return nil;
//}

#pragma mark NSObject

- (NSString*)description
{
    return [self.dictionary description];
}

#pragma mark - Extensions

#pragma mark RLASensorValue_Setup

- (instancetype)initWithDictionary:(NSDictionary *)values
{
    self = [super init];
    if (self)
    {
        _dictionary = values;
    }
    return self;
}

@end
