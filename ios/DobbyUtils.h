//
//  DobbyUtils.h
//  RNDobby
//
//  Created by rosefish on 2020/4/2.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN


@interface DobbyUtils : NSObject

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString;
+ (NSString *)getCachePath:(NSString * _Nullable)subDirName;
+ (void)requestPermission:(CLLocationManager *)locationManager;
+ (NSDictionary *)getConnectWiFi;
+ (BOOL) isWiFiEnabled;
+ (NSString *) getPhoneVersion;

@end

NS_ASSUME_NONNULL_END
