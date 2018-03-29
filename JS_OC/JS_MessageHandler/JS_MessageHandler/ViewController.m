//
//  ViewController.m
//  JavaScriptCoreDemo
//
//  Created by xinyu on 2018/3/26.
//  Copyright © 2018年 MaChat. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController ()<WKScriptMessageHandler, WKNavigationDelegate, WKUIDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView  *progressView;
@end

@implementation ViewController

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
}

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
    self.webView.navigationDelegate = self;
    
    NSString *urlStr = [[NSBundle mainBundle] pathForResource:@"index.html" ofType:nil];
    NSURL *fileURL = [NSURL fileURLWithPath:urlStr];
    [self.webView loadFileURL:fileURL allowingReadAccessToURL:fileURL];
    //进度条
    [self initProgressView];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"showMessageAction"];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"showTitleAndMessageAction"];
    [self.webView.configuration.userContentController addScriptMessageHandler:self name:@"doSomethingThenCallBackAction"];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"showMessageAction"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"showTitleAndMessageAction"];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"doSomethingThenCallBackAction"];
}

- (void)initProgressView {
    CGFloat kScreenWidth = [[UIScreen mainScreen] bounds].size.width;
    UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 2)];
    progressView.tintColor = [UIColor redColor];
    progressView.trackTintColor = [UIColor lightGrayColor];
    [self.view addSubview:progressView];
    self.progressView = progressView;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // 计算wkWebView进度条
    if (object == self.webView && [keyPath isEqualToString:@"estimatedProgress"]) {
        CGFloat newprogress = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        if (newprogress == 1) {
            [self.progressView setProgress:1.0 animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.progressView.hidden = YES;
                [self.progressView setProgress:0 animated:NO];
            });
            
        } else {
            self.progressView.hidden = NO;
            [self.progressView setProgress:newprogress animated:YES];
        }
    }
}

#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
    __weak typeof(self) weakSelf = self;
    // JS 调用OC 方法  传递一个参数
    if ([message.name isEqualToString:@"showMessageAction"]) {
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:@"提示" message:message.body preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    }
    // JS 调用OC 方法  传递多个参数
    if ([message.name isEqualToString:@"showTitleAndMessageAction"]) {
        NSDictionary *dict = message.body;
        UIAlertController *alertCtr = [UIAlertController alertControllerWithTitle:dict[@"title"] message:dict[@"content"] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
        [alertCtr addAction:cancel];
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    }
    
    if ([message.name isEqualToString:@"doSomethingThenCallBackAction"]) {
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
                // OC 调用JS 方法  并传递参数
                NSString *jsStr = [NSString stringWithFormat:@"callback('%@')",textField.text];
                [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                    NSLog(@"%@----%@",result, error);
                }];
            }];
            [alertCtr addAction:ok];
            ok.enabled = NO;
            
            [weakSelf presentViewController:alertCtr animated:YES completion:nil];
        });
    }
}

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


