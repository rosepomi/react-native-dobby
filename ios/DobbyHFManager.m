//
//  DobbyHFManager.m
//  Dobby.
//
//  Created by Dobby on 20-04-01.
//  Copyright (c) 2020 Dobby. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DobbyHFManager.h"
#import "HFSmartLink.h"
#import "HFAPLink.h"

@implementation DobbyHFManager {
	SmartLinkProcessBlock processBlock;
	SmartLinkSuccessBlock successBlock;
	SmartLinkFailBlock failBlock;
	SmartLinkEndblock endBlock;
}

+ (void)startSmartLink:(NSString *)ssid key:(NSString *)key withV3x:(BOOL)v3x timeout:(int)timeout processblock:(SmartLinkProcessBlock)pblock successBlock:(SmartLinkSuccessBlock)sblock failBlock:(SmartLinkFailBlock)fblock endBlock:(SmartLinkEndblock)eblock {
    NSLog(@"HF smartlink first start");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopSync];
        [[HFSmartLink shareInstence] startWithSSID:ssid Key:key UserStr:nil withV3x:v3x processblock:^(NSInteger process) {
#if DEBUG
            NSLog(@"HF smartlink start, process: %i", (int)process);
#endif
			pblock(process);
        } successBlock:^(HFSmartLinkDeviceInfo *dev) {
            NSLog(@"HF smartlink success, dev: %s", dev.description.UTF8String);
            NSLog(@"HF smartlink success, dev object: %@", dev);
			sblock(dev);
        } failBlock:^(NSString *failmsg) {
            NSLog(@"HF smartlink fail, msg: %s", failmsg.UTF8String);
			fblock(failmsg);
        } endBlock:^(NSDictionary *deviceDic) {
            NSLog(@"HF smartlink end, deviceDic: %s", deviceDic.description.UTF8String);
			eblock(deviceDic);
        }];
    });
}

+ (void)stopSync {
	HFSmartLink *instance = [HFSmartLink shareInstence];
    [instance stopWithBlock:^(NSString *stopMsg, BOOL isOk) {
#if DEBUG
        NSLog(@"HF smartlink stoped, stopMsg: %s, isOk: %i", stopMsg.UTF8String, (int)isOk);
#endif
    }];
}

+ (void)stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self stopSync];
    });
}

+ (void)startAPLink:(NSString *)ssid key:(NSString *)key hotspot:(NSString *)hotspot timeout:(int)timeout {
    NSLog(@"[DobbyHFManager.startAPLink] HF APlink start");
	[[HFAPLink shareInstance] startAPLink:ssid key:key hotspot:hotspot timeout:timeout];
}


@end
