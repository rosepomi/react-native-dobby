//
//  DobbyHFManager.h
//  Dobby.
//
//  Created by Dobby on 20-04-01.
//  Copyright (c) 2020 Dobby. All rights reserved.
//

#ifndef DobbyHFManager_h
#define DobbyHFManager_h

#import "HFSmartLinkDeviceInfo.h"

typedef void(^SmartLinkProcessBlock)(NSInteger process);
typedef void(^SmartLinkSuccessBlock)(HFSmartLinkDeviceInfo * _Nullable dev);
typedef void(^SmartLinkFailBlock)(NSString * _Nullable failmsg);
typedef void(^SmartLinkEndblock)(NSDictionary * _Nullable deviceDic);

@interface DobbyHFManager : NSObject

+ (void)startSmartLink:(NSString * _Nonnull)ssid key:(NSString * _Nullable)key withV3x:(BOOL)v3x timeout:(int)timeout processblock:(SmartLinkProcessBlock _Nullable )pblock successBlock:(SmartLinkSuccessBlock _Nullable )sblock failBlock:(SmartLinkFailBlock _Nullable )fblock endBlock:(SmartLinkEndblock _Nullable )eblock;

+ (void)startAPLink:(NSString * _Nonnull)ssid key:(NSString * _Nullable)key hotspot:(NSString * _Nonnull)hotspot timeout:(int)timeout;

+ (void)stop;

@end

#endif
