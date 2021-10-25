//
//  DobbyUtils.m
//  RNDobby
//
//  Created by rosefish on 2020/4/2.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "DobbyUtils.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <UIKit/UIKit.h>

@implementation DobbyUtils

+ (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString
{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        NSLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}

+ (NSString *)getCachePath:(NSString * _Nullable)subDirName
{
    NSString *path;
    if (subDirName == nil) {
        path = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/SISAppSDK"];
    } else {
        path = [NSHomeDirectory() stringByAppendingFormat:@"/Documents/SISAppSDK/%@", subDirName];
    }
    
    NSString *dir = [NSString stringWithFormat:@"%@/", path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![[NSFileManager defaultManager] fileExistsAtPath:dir]) {
        [fileManager createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        NSLog(@"create path: %@", dir);
    }
    return path;
}

+ (void)requestPermission:(CLLocationManager *)locationManager {
    
	NSLog(@"----------- locationManager: %@", locationManager);
    //iOS9.0以上系统除了配置info之外，还需要添加这行代码，才能实现后台定位，否则程序会crash
    if (@available(iOS 9.0, *)) {
        locationManager.allowsBackgroundLocationUpdates = YES;
    } else {
        // Fallback on earlier versions
    }
    [locationManager requestAlwaysAuthorization];  //一直保持定位
    [locationManager requestWhenInUseAuthorization]; //使用期间定位
}

+ (NSDictionary *)getConnectWiFi
{
    NSArray *ifs = (__bridge_transfer NSArray *)CNCopySupportedInterfaces();
	NSLog(@"----------- getConnectWiFi, ifs: %@", ifs);
    NSDictionary *info = nil;

    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer NSDictionary *)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }

    return info;
}

+ (BOOL) isWiFiEnabled {
    NSCountedSet * cset = [[NSCountedSet alloc] init];
    struct ifaddrs *interfaces;
    if( ! getifaddrs(&interfaces) ) {
        for( struct ifaddrs *interface = interfaces; interface; interface = interface->ifa_next) {
            if ( (interface->ifa_flags & IFF_UP) == IFF_UP ) {
                [cset addObject:[NSString stringWithUTF8String:interface->ifa_name]];
                
            }
        }
    }
    return [cset countForObject:@"awdl0"] > 1 ? YES : NO;
}

+ (NSString *) getPhoneVersion {
    return [[UIDevice currentDevice] systemVersion];
}
@end
