//
//  ViewController.m
//  JS_WebViewJavascriptBridge
//
//  Created by xinyu on 2018/3/26.
//  Copyright © 2018年 MaChat. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "WKWebViewJavascriptBridge.h"

@interface ViewController ()< WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKWebViewJavascriptBridge *webViewBridge;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    // 添加自适应屏幕宽度js调用的方法
    NSString *jSString = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkUserScript = [[WKUserScript alloc] initWithSource:jSString injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUserScript];
    
    config.userContentController = wkUController;
    
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:self.webView];
    
    self.webView.UIDelegate = self;
    
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"index.html" ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:urlStr];
    [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    
    self.webViewBridge = [WKWebViewJavascriptBridge bridgeForWebView:self.webView];
    [self.webViewBridge setWebViewDelegate:self];
    
    //注册事件
    [self registerFunction];
}

- (void)registerFunction {
    [self registerShowMessage];
    [self registerShowTitleAndMessage];
    [self registerDoSomethingThenCallBack];
}

- (void)registerShowMessage {
    __weak typeof(self) weakSelf = self;
    [self.webViewBridge registerHandler:@"showMessage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSString *message = nil;
        if ([data isKindOfClass:[NSString class]]) {
            message = data;
        }
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    }];
  
}

- (void)registerShowTitleAndMessage {
    __weak typeof(self) weakSelf = self;
    [self.webViewBridge registerHandler:@"showTitleAndMessage" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSDictionary *dict = data;
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:dict[@"titile"] message:dict[@"content"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    }];
}

- (void)registerDoSomethingThenCallBack{
    __weak typeof(self) weakSelf = self;
    [self.webViewBridge registerHandler:@"doSomethingThenCallBack" handler:^(id data, WVJBResponseCallback responseCallback) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:nil preferredStyle:UIAlertControllerStyleAlert];
            [alertCtr addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"请输入传入的数据!";
                [textField addTarget:weakSelf action:@selector(textFieldChange:) forControlEvents:UIControlEventEditingChanged];
            }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
            [alertCtr addAction:cancel];
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                UITextField *textField = [alertCtr.textFields firstObject];
                //OC 调用 JS 方法
                [self.webViewBridge callHandler:@"callback" data:@[textField.text] responseCallback:^(id responseData) {
                    NSLog(@"%@",responseData);
                }];
                
            }];
            [alertCtr addAction:ok];
            ok.enabled = NO;
            
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
        
    }];

}

#pragma mark - UITextField
- (void)textFieldChange:(UITextField *)sender {
    UIAlertController *alertCtr = (UIAlertController *)self.presentedViewController;
    UIAlertAction *okAction = [alertCtr.actions lastObject];
    if (sender.text.length > 0) {
        okAction.enabled = YES;
    } else {
        okAction.enabled = NO;
    }
}

@end
