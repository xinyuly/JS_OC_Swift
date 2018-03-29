//
//  ViewController.h
//  JS_JavaScriptCore
//
//  Created by xinyu on 2018/3/26.
//  Copyright © 2018年 MaChat. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol JSDelegate <JSExport>

- (void)showMessageToYou:(NSString *)message;
- (void)doActionCallBack;
- (void)showA:(NSString *)aString andB:(NSString*)bString;

@end

@interface ViewController : UIViewController


@end

