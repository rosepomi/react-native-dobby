//
//  HFSmartLink.h
//  SmartlinkLib
//
//  Created by wangmeng on 15/3/16.
//  Copyright (c) 2015年 HF. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HFSmartLinkDeviceInfo.h"

@interface HFAPLink : NSObject
+ (instancetype) shareInstance;
- (void) startAPLink:(NSString *)ssid key:(NSString *)key hotspot:(NSString *)hotspot timeout:(int)timeout;
@end
