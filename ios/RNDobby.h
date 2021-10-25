
#import <React/RCTBridgeModule.h>
#import <CoreLocation/CoreLocation.h>

@interface RNDobby : NSObject <RCTBridgeModule, CLLocationManagerDelegate>
+ (void) setLocationManager:(CLLocationManager *)manager;
+ (RCTResponseSenderBlock) getLocationCallback;
+ (void) setPermissionStatus:(int)status;

@end

