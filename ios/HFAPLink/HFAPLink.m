//
//  HFSmartLink.m
//  SmartlinkLib
//
//  Created by wangmeng on 15/3/16.
//  Copyright (c) 2015年 HF. All rights reserved.
//

#import <NetworkExtension/NEHotspotConfigurationManager.h>
#import <CoreLocation/CoreLocation.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <net/if.h>
#import <ifaddrs.h>
#import <UIKit/UIKit.h>
#import "HFAPLink.h"
#import "HttpRequest.h"
#import "LWControlHeader.h"
#import "Udpproxy.h"
#import "DobbyUtils.h"

#define V8_RANDOM_NUM          0xAA

@interface HFAPLink ()

@property (nonatomic, strong) NSString *netSSID; //模块要连的wifi
@property (nonatomic, strong) NSString *netPwd; //模块要连的wifi密码
@property (nonatomic, strong) NSString *currentSSID; //手机当前连接的wifi
@property (nonatomic, strong) NSString *deviceSSID; //设备wifi热点
@property (nonatomic, strong) Udpproxy * udp;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL isConnectDevcie;
@property (nonatomic, assign) BOOL isStartScan;
@property (nonatomic, strong) CLLocationManager *locationManager;
//@property (nonatomic, strong) LoadingView *loadV;
//@property (nonatomic, strong) AKAlertView *alertV;
@end

@implementation HFAPLink

+ (instancetype)shareInstance{
    static HFAPLink * me = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
         me = [[HFAPLink alloc]init];
    });
    return me;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (void)startAPLink:(NSString *)ssid key:(NSString *)key hotspot:(NSString *)hotspot timeout:(int)timeout {
    NSLog(@"[HFAPLink.startAPLink] HF APlink start");
	self.deviceSSID = hotspot;
	self.netSSID = ssid;
	self.netPwd = key;
	
	//获取手机版本号
	CGFloat version = [[DobbyUtils getPhoneVersion] floatValue];

	//检查当前连接的wifi
    if ([ssid containsString:@"hiflying_softap"]) {
		NSLog(@"[HFAPLink.startAPLink] select the WIFi the device will connect to, ssid: %@", ssid);
        [self performSelector:@selector(skipSettingVC) withObject:nil afterDelay:0.35];
	} else if (ssid.length == 0) {
		NSLog(@"[HFAPLink.startAPLink] select the WIFi the device will connect to, ssid is empty");
		[self performSelector:@selector(skipSettingVC) withObject:nil afterDelay:0.35];
	} else {
		//权限提醒
		if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined && version >= 13) {
			self.locationManager = [[CLLocationManager alloc] init];
			[self.locationManager requestWhenInUseAuthorization];
			[self  performSelector:@selector(configContentView) withObject:nil afterDelay:5];
			return;
		} else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && version >= 13) {
			[UIAlertController alertControllerWithTitle:@"Tips"
												message:@"To get the router name, go to the Settings page to open application location permissions."
										 preferredStyle:UIAlertControllerStyleAlert];
			[UIAlertAction actionWithTitle:@"OK"
									 style:UIAlertActionStyleDefault
								   handler:^(UIAlertAction * action) {
				NSLog(@"action = %@", action);
				[self skipSettingVC];
			}];
			return;
		}
	}
	
	//判断是否已经连接了热点
	self.currentSSID = [self getCurrentWifi];
    if ([self.currentSSID containsString:hotspot]) {
        //当前手机连接上了设备热点
        [self apConfigWithNetSSID:self.netSSID key:self.netPwd hotspot:hotspot];
    } else {
		if (version < 11) {
			//低于ios11版本，提示跳转到设置页
			[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
				NSLog(@"[HFAPLink.startAPLink] action = %@", action);
				[self skipSettingVC];
			}];
		} else {
			//ios11以上版本，自动连接设备热点
//			NSLog(@"[HFAPLink.startAPLink] begin go to setting");
//			[self skipSettingVC];
//			NSLog(@"[HFAPLink.startAPLink] back to here");
//			self.currentSSID = [self getCurrentWifi];
			[self connectToWiFi];
		}
	}
}

- (void) apConfigWithNetSSID:(NSString *)ssid key:(NSString *)key hotspot:(NSString *)hotspot {
	__weakSelf(self);
	[HttpRequest connectModuleWithWiFiPwd:key
							  withNetSSID:ssid
								 withSSID:hotspot
							  didLoadData:^(NSDictionary *result, NSError *err) {
		if (!err) {
			NSInteger suc = [result[@"RC"] integerValue];
			if (suc == 0) {
				//成功
				weakSelf.deviceSSID = hotspot;
				[weakSelf setDeviceRestartWithDeviceSSID:hotspot];
				//保存wifi名跟密码
				[weakSelf saveNetPWD];
			} else {
				//失败
				dispatch_async(dispatch_get_main_queue(), ^{
					id info = [weakSelf fetchSSIDInfo];
					NSLog(@"HF APlink failed, fetchSSIDInfo: %@", info);
//					weakSelf.currentSSIDLabel.text = [NSString stringWithFormat:@"Current Wi-Fi Connection:%@",[info objectForKey:@"SSID"]];
				});
			}
		} else {
			NSLog(@"发送配置请求失败");
			dispatch_async(dispatch_get_main_queue(), ^{
				id info = [weakSelf fetchSSIDInfo];
				NSLog(@"HF APlink failed, fetchSSIDInfo: %@", info);
			});
		}
	}];
}

- (void) setDeviceRestartWithDeviceSSID:(NSString *)ssid {
    
    __weakSelf(self);
	[HttpRequest setRestartCommandwithSSID:ssid
							   didLoadData:^(NSDictionary *result, NSError *err) {
		NSLog(@"[HFAPLink.setDeviceRestartWithDeviceSSID] result: %@, err: %@", result, err);
        if (!err) {
            NSInteger suc = [result[@"RC"] integerValue];
            if (suc == 0) {
                //成功
                dispatch_async(dispatch_get_main_queue(), ^{
                    // 2018.11.19 自动连接到之前配置的wifi热点
					if (@available(iOS 11.0, *)) {
						NEHotspotConfiguration *hotspotConfig = [[NEHotspotConfiguration alloc] initWithSSID:weakSelf.netSSID passphrase:weakSelf.netPwd isWEP:NO];
						[[NEHotspotConfigurationManager sharedManager] applyConfiguration:hotspotConfig completionHandler:^(NSError * _Nullable error) {
							NSLog(@"[HFAPLink.setDeviceRestartWithDeviceSSID] applyConfiguration, error: %@", error);
							
							NSString *currentSSid = [weakSelf getCurrentWifi];
							dispatch_async(dispatch_get_main_queue(), ^{
								id info = [weakSelf fetchSSIDInfo];
								NSLog(@"[HFAPLink.setDeviceRestartWithDeviceSSID] HF APlink failed, fetchSSIDInfo: %@", info);
//								weakSelf.currentSSIDLabel.text = [NSString stringWithFormat:@"Current Wi-Fi Connection:%@",[info objectForKey:@"SSID"]];
							});
							if ([currentSSid isEqualToString:self.deviceSSID]) {
								//连接上了设备热点
								dispatch_async(dispatch_get_main_queue(), ^{
//									[weakSelf hideLoadView];
								});
								
							}else if([currentSSid isEqualToString:self.netSSID]){
								//连接上了要配置的wifi
								dispatch_async(dispatch_get_main_queue(), ^{
//									[weakSelf hideLoadView];
									[weakSelf scan];
								});
							}else{
								//连接失败
								if (error.description.length > 0) {
									dispatch_async(dispatch_get_main_queue(), ^{
//										[weakSelf hideLoadView];
//										[weakSelf presentAlertWithMessage:error.description];
									});
								}
								
							}
						}];
					} else {
						// Fallback on earlier versions
					}
                    weakSelf.isStartScan = YES;
                });
            }else{
                //失败
                 dispatch_async(dispatch_get_main_queue(), ^{
                     id info = [weakSelf fetchSSIDInfo];
//                     weakSelf.currentSSIDLabel.text = [NSString stringWithFormat:@"Current Wi-Fi Connection:%@",[info objectForKey:@"SSID"]];
                 });
            }
        }else{
            LWLog(@"发送重启请求失败");
            dispatch_async(dispatch_get_main_queue(), ^{
                id info = [weakSelf fetchSSIDInfo];
//                weakSelf.currentSSIDLabel.text = [NSString stringWithFormat:@"Current Wi-Fi Connection:%@",[info objectForKey:@"SSID"]];
            });
        }
    }];
}

-(void)checkLoading{
    if (_isConnectDevcie) {
//        [self hideLoadView];
    }
}

- (void) connectToWiFi {
	if (@available(iOS 11.0, *)) {
		__weakSelf(self);
		_isConnectDevcie = YES;
		NSLog(@"[connectToWiFi] initWithSSID self.deviceSSID: %@", self.deviceSSID);
		NEHotspotConfiguration *hotspotConfig = [[NEHotspotConfiguration alloc] initWithSSID:self.deviceSSID];
//        [self performSelector:@selector(checkLoading) withObject:nil afterDelay:6];
		[[NEHotspotConfigurationManager sharedManager] applyConfiguration:hotspotConfig completionHandler:^(NSError * _Nullable error) {
			NSLog(@"[connectToWiFi] applyConfiguration error: %@", error);
			weakSelf.isConnectDevcie = NO;
			dispatch_async(dispatch_get_main_queue(), ^{
				id info = [weakSelf fetchSSIDInfo];
				NSLog(@"[connectToWiFi] info: %@", info);
//				weakSelf.currentSSIDLabel.text = [NSString stringWithFormat:@"Current Wi-Fi Connection:%@",[info objectForKey:@"SSID"]];
			});
			NSString *currentSSid = [weakSelf getCurrentWifi];
			if ([currentSSid isEqualToString:self.deviceSSID]) {
				//连接成功
				weakSelf.currentSSID = self.deviceSSID;
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
					[weakSelf apConfigWithNetSSID:self.netSSID key:weakSelf.netPwd hotspot:self.deviceSSID];
				});
			} else {
				//连接失败
				if (error.description.length > 0) {
					dispatch_async(dispatch_get_main_queue(), ^{
						NSLog(@"[connectToWiFi] getCurrentWifi error %@", error.description);
//						[weakSelf hideLoadView];
//						[weakSelf presentAlertWithMessage:error.description];
					});
				}
			}
		}];
	}
}
-(void)saveNetPWD{
    [[NSUserDefaults standardUserDefaults]setObject:self.netPwd forKey:self.netSSID];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (id)fetchSSIDInfo {
    NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) { break; }
    }
    return info;
}

-(NSString *)getCurrentWifi{
    NSString *ssid = nil;
    NSArray *ifs = (__bridge   id)CNCopySupportedInterfaces();
    for (NSString *ifname in ifs) {
        NSDictionary *info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifname);
        if (info[@"SSID"])
        {
            ssid = info[@"SSID"];
        }
    }
    return ssid;
}

- (void) configContentView {
    NSString* phoneVersion = [[UIDevice currentDevice] systemVersion];
	CGFloat version = [phoneVersion floatValue];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined && version >= 13) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager requestWhenInUseAuthorization];
        [self  performSelector:@selector(configContentView) withObject:nil afterDelay:5];
        return;
    } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && version >= 13) {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Title"
																	   message:@"To get the router name, go to the Settings page to open application location permissions."
                                                                preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
																style:UIAlertActionStyleDefault
															  handler:^(UIAlertAction * action) {
			NSLog(@"action = %@", action);
			[self skipSettingVC];
		}];
//        [alert addAction:defaultAction];
//        [self presentViewController:alert animated:YES completion:nil];
    
        return;
    }
}

- (void) skipSettingVC {
	[[UIApplication sharedApplication] openURL: [NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

-(void)scan{
    
    [self.timer invalidate];
    self.timer = nil;
    [self.udp close];
    sleep(1);
    if (self.udp) {
        [self.udp CreateBindSocket];

    }else{
        self.udp = [Udpproxy shareInstence];
        [self.udp CreateBindSocket];

    }
    __weakSelf(self);
//    BOOL isPerform = true;
//    while (isPerform) {
//        [self.udp sendSmartLinkFind];
//        LWLog(@"%@ 发送广播包",[NSDate date]);
////        sleep(0.5);
//        HFSmartLinkDeviceInfo * dev = [weakSelf.udp recv:V8_RANDOM_NUM];
//                if (dev) {
//                    dispatch_async(dispatch_get_main_queue(), ^{
//        //                [weakSelf hideLoadView];
//                        [weakSelf.activityV stopAnimating];
//                        weakSelf.whiteView.hidden = YES;
//                        [weakSelf presentAlertWithMessage:[NSString stringWithFormat:@"MAC:%@\n ip:%@",dev.mac,dev.ip]];
//                    });
//                    break;
////                    [weakSelf.timer invalidate];
////                    weakSelf.timer = nil;
//                }
//
//        sleep(0.5);
//
//
//    }
    [self.udp sendSmartLinkFind];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0f repeats:YES block:^(NSTimer * _Nonnull timer) {
        
        NSLog(@"搜索局域网设备--%@ 线程：%@", [NSDate date], [NSThread currentThread]);
        [weakSelf.udp sendSmartLinkFind];
        
        HFSmartLinkDeviceInfo * dev = [weakSelf.udp recv:V8_RANDOM_NUM];
        if (dev) {
            dispatch_async(dispatch_get_main_queue(), ^{
//                [weakSelf hideLoadView];
//                [weakSelf.activityV stopAnimating];
//                weakSelf.whiteView.hidden = YES;
//                [weakSelf presentAlertWithMessage:[NSString stringWithFormat:@"MAC:%@\n ip:%@",dev.mac,dev.ip]];
				NSLog(@"[HFAPLink.scan] mac: %@ ip: %@", dev.mac, dev.ip);
            });
            [weakSelf.timer invalidate];
            weakSelf.timer = nil;
        }
    }];
    [[NSRunLoop mainRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
}
#pragma delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    id alertbutton = [alertView buttonTitleAtIndex:buttonIndex];
    NSLog(@"按下了[%@]按钮",alertbutton);
}
@end
