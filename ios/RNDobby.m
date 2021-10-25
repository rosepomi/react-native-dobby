
#import "RNDobby.h"
#import <UIKit/UIAlertView.h>
#import <UIKit/UIApplication.h>
#import <React/RCTBridgeModule.h>
#import "DobbyHFManager.h"
#import "DobbyUtils.h"

static RNDobby *_instance = nil;
static CLLocationManager *_locationManager;
static RCTResponseSenderBlock _locationCallback;
static int _permissionStatus;

@implementation RNDobby
- (dispatch_queue_t)methodQueue{
    return dispatch_get_main_queue();
}

+ (instancetype) sharedInstance {
	if (!_instance) {
		_instance = [[self alloc] init];
	}
	return _instance;
}

+ (RCTResponseSenderBlock) getLocationCallback {
	return _locationCallback;
}

+ (void) setPermissionStatus:(int)status {
	_permissionStatus = status;
}

RCT_EXPORT_MODULE(RNDobby)
+ (void)setLocationManager:(CLLocationManager *)manager {
	_locationManager = manager;
}

RCT_EXPORT_METHOD(runPhoenix:(NSDictionary * _Nullable)param callback:(RCTResponseSenderBlock)callback) {
    NSLog(@"----------- runPhoenix ----------------");
	NSString *logPath = [DobbyUtils getCachePath:@"sislog"];
	NSString *jsonPath = [DobbyUtils getCachePath:@"json"];
	NSString *rootPath = [DobbyUtils getCachePath:nil];
	if (callback) {
		callback(@[rootPath, logPath, jsonPath]);
	}
}

RCT_EXPORT_METHOD(sislog:(NSString * _Nullable)info
				  content:(NSString * _Nullable)content) {
    NSLog(@"----------- sislog ----------------");
	//  [SISDobby dobbyLog:info content:content];
}

RCT_EXPORT_METHOD(requestPermission:(RCTResponseSenderBlock)callback) {
	NSLog(@"----------- requestPermission ----------------");
	_locationCallback = callback;
	if ([CLLocationManager locationServicesEnabled]
		&& ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse ||
			[CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
		if (callback) {
			callback(@[[NSNumber numberWithInt:[CLLocationManager authorizationStatus]]]);
		}
	} else {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		[_locationManager requestWhenInUseAuthorization];
	}
}

RCT_EXPORT_METHOD(getConnectWiFi:(RCTResponseSenderBlock)callback) {
	NSLog(@"----------- getConnectWiFi ----------------");
	NSDictionary *wifi = [DobbyUtils getConnectWiFi];
	NSLog(@"----------- wifi: %@", wifi);
	if (callback) {
		if (wifi) {
			callback(@[@"success", wifi]);
		} else {
			callback(@[@"failed"]);
		}
	}
}

/**
 ssid: wifii名字
 key: wifi密码
 module: 模组型号 LPB100、LPB120、LPB130、LPT230
 hotspot: 设备热点名字
  linkType: 配网类型，0为smartConfig，1为软AP
 timeout: 配网时长
 */
RCT_EXPORT_METHOD(startDeviceLink:(NSString *)ssid key:(NSString *)key module:(NSString *)module hotspot:(NSString *)hotspot linkType:(int)linkType timeout:(int)timeout callback:(RCTResponseSenderBlock)callback) {
	if (linkType == 0) {
		NSLog(@"----------- startDeviceLink SmartConfig ---------------- module: %@", module);
		BOOL v3x = ([module isEqualToString:@"LPB130"] || [module isEqualToString:@"LPT230"]) ? NO : YES;
		[DobbyHFManager startSmartLink:ssid key:key withV3x:v3x timeout:timeout processblock: ^(NSInteger pro) {
							 } successBlock:^(HFSmartLinkDeviceInfo *dev) {
								 NSLog(@"----------- successBlock");
								 if (callback) {
									 callback(@[@"success", @{@"mac":dev.mac, @"ip":dev.ip}]);
								 }
							 } failBlock:^(NSString *failmsg) {
								 NSLog(@"----------- failBlock");
								 if (callback) {
									 callback(@[@"failed", @{@"message": failmsg}]);
								 }
							 } endBlock:^(NSDictionary *deviceDic) {
								 NSLog(@"----------- endBlock");
		//						 if (callback) {
		//							 callback(@[@"end", @{@"message": @"smart link stopped"}]);
		//						 }
							 }];
	} else {
		NSLog(@"----------- startDeviceLink APConfig ---------------- hotspot: %@", hotspot);
		[DobbyHFManager startAPLink:ssid key:key hotspot:hotspot timeout:timeout];
	}
}

RCT_EXPORT_METHOD(stopDeviceLink:(int)linkMode) {
	NSLog(@"----------- stopDeviceLink ----------------");
	[DobbyHFManager stop];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"----------- RNDobby didChangeAuthorizationStatus ----------------");
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [_locationManager requestWhenInUseAuthorization];     //NSLocationWhenInUseDescription
                [_locationManager requestAlwaysAuthorization];
            }
            break;
		case kCLAuthorizationStatusDenied: {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"未授权定位权限"
																message:@"请打开手机设置中的'隐私-位置'，允许App使用定位权限添加设备"
															   delegate:self
													  cancelButtonTitle:@"取消"
													  otherButtonTitles:@"前往设置", nil];
			alertView.tag = 1000;
			[alertView show];
			if (_locationManager) {
				_locationManager = nil;
			}
			break;
		}
        case kCLAuthorizationStatusAuthorizedWhenInUse:
        case kCLAuthorizationStatusAuthorizedAlways:
			if (_locationCallback) {
                _locationCallback(@[[NSNumber numberWithInt:status]]);
            };
			if (_locationManager) {
				_locationManager = nil;
			}
            break;
        default:
            break;
    }
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1000) {
        if (buttonIndex == 1) {
            NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if ([[UIApplication sharedApplication]canOpenURL:url]) {
                [[UIApplication sharedApplication]openURL:url];
            }
        }
    }
}
@end
  
