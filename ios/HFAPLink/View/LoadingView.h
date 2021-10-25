//
//  LoadingView.h
//  guangDian
//
//  Created by peng on 16/4/12.
//  Copyright © 2016年 yunwan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoadingView : UIView

-(instancetype)init;
-(void)show;
- (void)dismiss;
-(void)setDescribleStr:(NSString *)desStr;
-(void)showWithView:(UIView *)showView;
@end
